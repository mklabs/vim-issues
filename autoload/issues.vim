" vim-issues.vim - Little Vim plugin to browse github issues
" Maintainer:      mklabs

" if exists("g:autoloaded_issues") || v:version < 700 || &cp
"   finish
" endif
" let g:autoloaded_issues = 1

" Object.create like prototype-like create
let s:Object = {}
function! s:Object.create(...)
  let F = copy(self)
  if a:0
    let F = extend(self, a:1)
  endif
  return F
endfunction

" utilities

function! s:has(line, pat)
  return matchstr(a:line, a:pat) != ''
endfunction

function! s:map(list, prefix)
  return map(copy(a:list), 'a:prefix . v:val')
endfunction

" json parser / serializer borrowed to vim-rhubarb
function! s:throw(string) abort
  let v:errmsg = 'json: '.a:string
  throw v:errmsg
endfunction

function! s:json_parse(string) abort
  let [null, false, true] = ['', 0, 1]
  let stripped = substitute(a:string,'\C"\(\\.\|[^"\\]\)*"','','g')
  if stripped !~# "[^,:{}\\[\\]0-9.\\-+Eaeflnr-u \n\r\t]"
    try
      return eval(substitute(a:string,"[\r\n]"," ",'g'))
    catch
    endtry
  endif
  call s:throw("invalid JSON: ".stripped)
endfunction

function! s:json_generate(object) abort
  if type(a:object) == type('')
    return '"' . substitute(a:object, "[\001-\031\"\\\\]", '\=printf("\\u%04x", char2nr(submatch(0)))', 'g') . '"'
  elseif type(a:object) == type([])
    return '['.join(map(copy(a:object), 's:json_generate(v:val)'),', ').']'
  elseif type(a:object) == type({})
    let pairs = []
    for key in keys(a:object)
      call add(pairs, s:json_generate(key) . ': ' . s:json_generate(a:object[key]))
    endfor
    return '{' . join(pairs, ', ') . '}'
  else
    return string(a:object)
  endif
endfunction


" issues prototype
let s:issues = {}

" dirname
let s:issues.basedir = expand('<sfile>:h:h')
let s:issues.script = join([s:issues.basedir, 'bin/issues'], '/')

" init this new issue object
function! s:issues.init(...)
  call self.repo()
endfunction

" spawn the node script in bin/<file> with args as cli options
function! s:issues.exec(args)
  call extend(a:args, ['--repo', self.github_repo])
  return s:json_parse(system('node ' . self.script . ' ' . join(a:args, ' ')))
endfunction

" same but using :! variant
function! s:issues.shell(args)
  exe ':!node ' self.script join(a:args, ' ')
endfunction

" borrowed to vim-rhubarb, reads git config through fugitive api, set local
" buffer github_repo variable and returns the matching url
function! s:issues.repo()
  if !exists('b:github_repo')
    let repo = fugitive#buffer().repo()
    let url = repo.config('remote.origin.url')
    if url !~# 'github\.com[:/][^/]*/[^/]*\.git'
      return
    endif
    let b:github_repo = matchstr(url,'github\.com[:/]\zs[^/]*/[^/]*\ze\.git')
  endif
  let self.github_repo = b:github_repo
  return b:github_repo
endfunction

" returns remote issues as a dictionary
let s:qflist = []
function! s:issues.list(...)
  let issues = self.exec(['--command', 'list'])
  let qflist = []
  for issue in issues
    " ['labels', 'number', 'comments', 'updated_at', 'title', 'created_at',
    " 'user', 'gravatar_id', 'votes', 'state', 'position', 'body', 'html_url']

    " Store the issue as qf compatible item
    let qfitem = {}
    " let qfitem.filename = issue.title
    " XXX pad titles & nums
    let qfitem.lnum = issue.number
    let qfitem.text = issue.user.login . ' | ' . issue.title

    " non standard to qflist, just placed here for further use in preview
    let qfitem.issue = issue
    call add(qflist, qfitem)
  endfor

  " update the qflist with action set to 'r'
  call setqflist(qflist, 'r')

  " close / open quickfix window depending on errors length
  let hasError = !empty(qflist)

  if hasError
    exe 'copen'
    let s:qflist = qflist
    silent doautocmd User GhIssues
    let hint = '<Enter> to show issue content | o to open the issue below the cursor in default browser'
    exe 'setlocal statusline=' . fnameescape(self.github_repo . ' issues | ' . hint)
  elseif
    exe 'cclose'
  endif
endfunction


" Preview

function! s:Preview(line)
  call s:InitPreview(a:line)
  call issues#PreviewMappings()
endfunction

" thx @AndrewRadev:
" based on https://gist.github.com/1688979

let s:preview_buffer = '__ghissues__'
function! s:InitPreview(line)
  if empty(s:qflist)
    return
  endif

  let preview_file = s:preview_buffer
  if bufwinnr(preview_file) < 0
    let original_buffer = bufnr('%')
    exe "silent edit " . preview_file
  endif

  call s:SwitchWindow(preview_file)
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal filetype=markdown

  let issue = s:GetIssue(a:line)
  let output = [
    \ issue.title,
    \ '',
  \ ]

  call extend(output, split(issue.body, "\n"))

  setlocal modifiable
  exe ':silent normal! ggVGd'
  call append(0, output)

  if issue.comments != 0 && exists('s:issue')
    let loading = 'Loading comments... ' . issue.comments
    call append(line('$'), ['', loading])
    echo "Loading comments..."
    exe ':silent $r! node ' . s:issue.script . ' --command comments --repo ' . s:issue.github_repo . ' --id ' . issue.number
    exe 'silent %s/' . loading . '//'
  endif

  let hint = 'Type q to close the preview - Type o the open this issue in your default browser'
  exe 'setlocal statusline=' . fnameescape(join([
    \ issue.title, 'Created: ' . issue.created_at,
    \ 'Author: ' .  issue.user.login,
    \ hint
  \ ], ' | '))

  exe ':silent! %s/\r//g'
  exe ':silent! g/^[^ ]/:normal Vgq/'

  " match titles, and append a series of '=' below
  exe ':silent! g/^' . issue.title . '/t.|s/./=/g'

  " set to nomodifiable
  setlocal nomodifiable
  " resize window to highest possible
  exe ':resize'

  let b:issue = issue
endfunction

function! s:PreviewURL(...)
  let issue = a:0 ? a:1 : s:GetIssue(getline('.')).number
  let url = 'https://github.com/' . s:issue.github_repo . '/issues/' . issue
  echo '... Opening ' . url . ' ...'
  call s:OpenURL(url)
endfunction

function! s:PreviewClose()
  " close preview buffer
  exe ':q!'
  " and switch back to quickfix window
  exe ':copen'
  " remap
  silent doautocmd User GhIssues
endfunction

function! s:GetIssue(line)
  let num = matchstr(a:line, '\d\+')
  let issue = filter(copy(s:qflist), 'v:val.lnum == ' . num)
  return get(issue, 0).issue
endfunction

" Switch to the window that a:bufname is located in.
function! s:SwitchWindow(bufname)
  let window = bufwinnr(a:bufname)
  exe window.'wincmd w'
endfunction

" open url helper, defaulting to according command depending on env
function! s:OpenURL(url)
  if has("gui_mac") || has("gui_macvim") || exists("$SECURITYSESSIONID")
    let cmd = ':!open'
  elseif has("gui_win32")
    let cmd = '!start cmd /cstart /b'
  elseif executable("sensible-browser")
    let cmd = '!sensible-browser'
  elseif executable('launchy')
    let cmd = '!launchy'
  elseif executable('git')
    command -bar -nargs=1 OpenURL :!git web--browse <args>
    let cmd = '!git web--browse'
  endif
  exe ':silent! ' . cmd . ' ' . a:url
endfunction


" Public API

" returns a new issues object
function! issues#create()
  let issue = s:Object.create(s:issues)
  call issue.init()
  " let's store the last create instance to s:issue
  let s:issue = issue
  return issue
endfunction

function! issues#QuickfixEnter()
  exe '.cc' line('.')
  call s:Preview(getline('.'))
endfunction

function! issues#QuickfixMappings()
  nnoremap <buffer> <silent> <CR> :call issues#QuickfixEnter()<CR>
  nnoremap <buffer> <silent> o :call <sid>PreviewURL()<CR>
endfunction

function! issues#PreviewMappings()
  nnoremap <buffer> <silent> q :call <sid>PreviewClose()<CR>
  nnoremap <buffer> <silent> o :call <sid>PreviewURL(getbufvar('%', 'issue').number)<CR>
endfunction


