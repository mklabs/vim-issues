
issues.vim
==========

**Vim plugin to browse github issues**

Description
-----------

This plugin defines a single command `:GhIssue`. Edit a buffer within a git
repo to make it available (and `git config remote.origin.url` should point to a
GitHub repo)

You can then quickly navigate through the opened issue by hitting:

* `<Enter>` in the quickfix window to show the given issue body and
  comments
* `q` to close the preview window and reopen the quickfix list.
* `o` in both list and preview window would open the given issue on
  GitHub

That's pretty much all it does.. Maybe some more github-buddy related things
will be added, probably to do the same on public / private gists. Or
maybe something to navigate github repositories from within a buffer.

Install
-------

[fugitive](https://github.com/tpope/vim-fugitive) is required for this plugin
to work. It's used to guess the repo for the current buffer and init the plugin
functionality on `User Fugitive` event.

[node](http://nodejs.org) is required as well, it should be installed and
available in your path. Parts of this plugin functionnality is delegated to a
basic node script (to request the github api mainly).

If you don't have a preferred installation method, I recommend
installing [pathogen.vim](https://github.com/tpope/vim-pathogen), and
then simply git clone this repo at `~/.vim/bundle/vim-issues`

What it does
-----------

When editing a buffer within a git repo, running `:GhIssues` will open
the quickfix window with the list of opened issues.

![GhIssues command](https://raw.github.com/mklabs/vim-issues/master/doc/ghissues.png)

Buffer specific mappings are available:

* Hitting `<Enter>` will open the issue below the cursor in a preview
  window.

* Hitting `o` will open the issue below the cursor in default browser.

Hitting `<Enter>` on the third line switch the quickfix window to a
preview buffer, with extended informations about the given issue
including issue body and loading comments if there are.

The window is resized to maximum height by default.

![Preview](https://raw.github.com/mklabs/vim-issues/master/doc/issue-preview.png)

Same here, buffer specific mappings are defined:

* Just like in the quickfix window, hitting `o` will open the issue thread in a web browser

* Hitting `q` will close the preview window and switch back to the issue
  listing.

