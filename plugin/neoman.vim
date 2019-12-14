if exists('g:loaded_neoman')
  finish
endif
let g:loaded_neoman = 1

let g:neoman_find_window = get(g:, 'neoman_find_window', 1 )

function! s:new_tab()
  if get( g:, 'neoman_tab_after', 0 ) == 1
    return 'tabnew'
  else
    return (tabpagenr()-1).'tabnew'
  endif
endfunction

" TODO(nhooyr) using a default count of 10 is a very inelegant solution
command! -count=10 -complete=customlist,neoman#complete -nargs=* Nman call
      \ neoman#get_page(<count>, 'edit', <f-args>)
command! -count=10 -complete=customlist,neoman#complete -nargs=* Snman call
      \ neoman#get_page(<count>, 'split', <f-args>)
command! -count=10 -complete=customlist,neoman#complete -nargs=* Vnman call
      \ neoman#get_page(<count>, 'vsplit', <f-args>)
command! -count=10 -complete=customlist,neoman#complete -nargs=* Tnman call
      \ neoman#get_page(<count>, <SID>new_tab(), <f-args>)

nnoremap <silent> <Plug>(Nman)  :<C-U>call neoman#get_page(v:count, 'edit', expand('<cWORD>'))<CR>
nnoremap <silent> <Plug>(Snman)  :<C-U>call neoman#get_page(v:count, 'split', expand('<cWORD>'))<CR>
nnoremap <silent> <Plug>(Vnman)  :<C-U>call neoman#get_page(v:count, 'vsplit', expand('<cWORD>'))<CR>
nnoremap <silent> <Plug>(Tnman)  :<C-U>call neoman#get_page(v:count, <SID>new_tab(), expand('<cWORD>'))<CR>
