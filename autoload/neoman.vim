" Ensure Vim is not recursively invoked (man-db does this)
" by removing MANPAGER from the environment
" More info here http://comments.gmane.org/gmane.editors.vim.devel/29085
if &shell =~# 'fish$'
  let s:man_cmd = 'man -P cat ^/dev/null '
else
  let s:man_cmd = 'man -P cat 2>/dev/null '
endif

let s:man_sect_arg = ''
let s:man_find_arg = '-w'
let s:tag_stack = []

try
  if !has('win32') && $OSTYPE !~? 'cygwin\|linux' && system('uname -s') =~? 'SunOS' && system('uname -r') =~? '^5'
    let s:man_sect_arg = '-s'
    let s:man_find_arg = '-l'
  endif
catch /E145:/
  " Ignore the error in restricted mode
endtry

function! neoman#get_page(count, editcmd, ...) abort
  if a:0 > 2
    call s:error('too many arguments')
    return
  elseif a:0 == 0
    call s:error('what manual page do you want?')
    return
  elseif a:0 == 1
    let [page, sect] = s:parse_page_and_sect_fpage(a:000[0])
    if (empty(sect) && sect != 0) && a:count != 10
      let sect = a:count
    endif
  else
    let sect = tolower(a:000[0])
    let page = a:000[1]
  endif

  let out = systemlist(s:man_cmd.s:man_find_arg.' '.s:man_args(sect, page))
  if empty(out) || out[0] == ''
    call s:error('no manual entry for '.page.(s:empty_sect(sect)?'':'('.sect.')'))
    return
  elseif page !~# '\/'
    " if page is not a path, parse the page and section from the path
    " use the last line because if we had something like printf(man) then man
    " would be read as the manpage because man's path is at out[0]
    let [page, sect] = s:parse_page_and_sect_path(out[len(out)-1])
  endif

  call s:push_tag()

  call s:read_page(sect, page, a:editcmd)
endfunction

" move to previous position in the stack
function! neoman#pop_tag() abort
  if !empty(s:tag_stack)
    let tag = remove(s:tag_stack, -1)
    execute tag['buf'].'b'
    call cursor(tag['lnum'], tag['col'])
  endif
endfunction

" save current position in the stack
function! s:push_tag() abort
  let s:tag_stack += [{
        \ 'buf':  bufnr('%'),
        \ 'lnum': line('.'),
        \ 'col':  col('.'),
        \ }]
endfunction

" find the closest neoman window above/left
function! s:find_neoman(cmd) abort
  if g:neoman_find_window != 1 || &filetype ==# 'neoman'
    return a:cmd
  endif
  if winnr('$') > 1
    let thiswin = winnr()
    while 1
      if &filetype ==# 'neoman'
        return 'edit'
      endif
      wincmd w
      if thiswin == winnr()
        return a:cmd
      endif
    endwhile
  endif
  return a:cmd
endfunction

" parses the page and sect out of 'page(sect)'
function! s:parse_page_and_sect_fpage(fpage) abort
  let ret = split(a:fpage, '(')
  if len(ret) > 1
    let iret = split(ret[1], ')')
    return [ret[0], tolower(iret[0])]
  endif
  return [ret[0], '']
endfunction

" parses the page and sect out of 'path/page.sect'
function! s:parse_page_and_sect_path(path) abort
  " regex for valid extensions that manpages can have
  if a:path =~# '\.\%([glx]z\|bz2\|lzma\|Z\)$'
    let tail = fnamemodify(fnamemodify(a:path, ':r'), ':t')
  else
    let tail = fnamemodify(a:path, ':t')
  endif
  let page = matchstr(tail, '^\f\+\ze\.')
  let sect = matchstr(tail, '\.\zs[^.]\+$')
  return [page, sect]
endfunction

function! s:read_page(sect, page, cmd)
  execute s:find_neoman(a:cmd) 'man://'.a:page.(s:empty_sect(a:sect)?'':'('.a:sect.')')
  setlocal modifiable
  " TODO perhaps do not load, merely redisplay?
  " remove all the text, incase we already loaded the manpage before
  keepjumps %delete _
  if &number
    let num_offset = max([&numberwidth, strwidth(line('$'))+1]) " added one for the space before text
  elseif &relativenumber
    let num_offset = max([&numberwidth, strwidth(winheight(0))+1]) " added one for the space before text
  else
    let num_offset = 0
  endif
  " TODO find a way to include sign column
  let text_width = winwidth(0)-&foldcolumn-num_offset
  if $MANWIDTH < text_width
    let $MANWIDTH = text_width
  endif
  " read manpage into buffer
  silent execute 'r!'.s:man_cmd.s:man_args(a:sect, a:page)
  " remove all those backspaces
  silent execute 'keeppatterns keepjumps %substitute,.\b\|\e\[\d\+m,,e'.(&gdefault?'':'g')
  silent keepjumps 1delete _
  setlocal filetype=neoman
endfunction

function! s:man_args(sect, page) abort
  if a:sect != 10 && (!empty(a:sect) || a:sect == 0)
    return s:man_sect_arg.' '.shellescape(a:sect).' '.shellescape(a:page)
  endif
  return shellescape(a:page)
endfunction
"
" checks if sect is empty
function! s:empty_sect(sect)
  return a:sect == 10 || (a:sect != 0 && empty(a:sect))
endfunction

function! s:error(msg) abort
  redrawstatus!
  echon 'neoman.vim: '
  echohl ErrorMsg
  echon a:msg
  echohl None
endfunction

function! s:init_mandirs() abort
  let mandirs_list = split(system(s:man_cmd.s:man_find_arg), ':\|\n')
  " removes duplicates and then join by comma
  let s:mandirs = join(filter(mandirs_list, 'index(mandirs_list, v:val, v:key+1)==-1'), ',')
endfunction
call s:init_mandirs()

function! neoman#complete(arg_lead, cmd_line, cursor_pos) abort
  let args = split(a:cmd_line)
  let l = len(args)
  " if already completed a manpage, we return
  if (l > 1 && args[1] =~# ')\f*$') || l > 3
    return
  elseif l == 3
    " cursor (|) is at ':Nman 3 printf |'
    if empty(a:arg_lead)
      return
    endif
    let page = a:arg_lead
    let sect = tolower(args[1])
  elseif l == 2
    " cursor (|) is at ':Nman 3 |'
    if empty(a:arg_lead)
      let page = ''
      let sect = tolower(args[1])
    elseif a:arg_lead =~# '^\f\+(\f*$'
      " cursor (|) is at ':Nman printf(|'
      let tmp = split(a:arg_lead, '(')
      let page = tmp[0]
      let sect = tolower(get(tmp, 1, ''))
    else
      " cursor (|) is at ':Nman printf|'
      " if the page is a path, complete files
      if a:arg_lead =~# '\/'
        "TODO why does this complete the last one automatically
        return glob(a:arg_lead.'*', 0, 1)
      endif
      let page = a:arg_lead
      let sect = ''
    endif
  else
    let page = ''
    let sect = ''
  endif
  return map(globpath(s:mandirs,'*/'.page.'*.'.sect.'*', 0, 1), 's:format_candidate(v:val, sect)')
endfunction

function! s:format_candidate(c, sect) abort
  let [page, sect] = s:parse_page_and_sect_path(a:c)
  if sect ==# a:sect
    return page
  elseif sect =~# a:sect.'[^.]\+$'
    return page.'('.sect.')'
  endif
endfunction
