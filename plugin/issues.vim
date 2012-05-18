" vim-issues.vim -  Little Vim plugin to browse github issues
" Maintainer:       mklabs

" if exists("g:loaded_issues") || v:version < 700 || &cp
"   finish
" endif
" let g:loaded_issues = 1

" autodetect and initialize the plugin if within a git repo

let s:commands = []
function! s:command(definition) abort
  let s:commands += [a:definition]
endfunction

function! s:define_commands()
  if !exists('b:git_dir')
    return
  endif
  for command in s:commands
    exe 'command! -buffer '.command
  endfor
endfunction

function! s:QuickfixMappings()
  call issues#QuickfixMappings()
endfunction


" Public API

" Commands
" --------

call s:command("-nargs=? GhIssues :call issues#create().list(<q-args>)")

augroup ghissues
  autocmd!
  autocmd BufEnter * call s:define_commands()
  autocmd User Fugitive call s:define_commands()
  autocmd User GhIssues call s:QuickfixMappings()
augroup END




" vim:set sw=2 sts=2:
