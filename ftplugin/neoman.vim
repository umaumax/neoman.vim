if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:pager = 0

if has('vim_starting')
  let s:pager = 1
  " remove all those backspaces
  silent execute 'keeppatterns keepjumps %substitute,.\b\|\e\[\d\+m,,e'.(&gdefault?'':'g')
  execute 'file '.'man://'.tolower(matchstr(getline(1), '^\S\+'))
  keepjumps 1
endif

setlocal buftype=nofile
setlocal noswapfile
setlocal nofoldenable
setlocal bufhidden=hide
setlocal nobuflisted
setlocal nomodified
setlocal readonly
setlocal nomodifiable
setlocal noexpandtab
setlocal tabstop=8
setlocal softtabstop=8
setlocal shiftwidth=8
setlocal nolist
setlocal foldcolumn=0
setlocal colorcolumn=0
setlocal nonumber
setlocal norelativenumber
setlocal foldcolumn=0

if !exists('g:no_plugin_maps') && !exists('g:no_neoman_maps')
  nnoremap <silent> <buffer> <C-]>      :<C-U>call neoman#get_page(v:count, 'edit', expand('<cWORD>'))<CR>
  if &keywordprg !=# ':Nman'
    nmap   <silent> <buffer> <K>        <C-]>
  endif
  nnoremap <silent> <buffer> <C-t>      :call neoman#pop_tag()<CR>
  if s:pager
    nnoremap <silent> <buffer> <nowait> q :q<CR>
  else
    nnoremap <silent> <buffer> <nowait> q <C-W>c
  endif
endif

let b:undo_ftplugin = ''
