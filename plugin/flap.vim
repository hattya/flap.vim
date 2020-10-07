" File:        plugin/flap.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2020-10-07
" License:     MIT License

if exists('g:loaded_flap')
  finish
endif
let g:loaded_flap = 1

let s:save_cpo = &cpo
set cpo&vim

nnoremap <silent> <Plug>(flap-inc)   :<C-U>call flap#nflap(v:count1)<CR>
vnoremap <silent> <Plug>(flap-inc)   :<C-U>call flap#vflap(v:count1, 0)<CR>
vnoremap <silent> <Plug>(flap-inc-g) :<C-U>call flap#vflap(v:count1, 1)<CR>

nnoremap <silent> <Plug>(flap-dec)   :<C-U>call flap#nflap(-v:count1)<CR>
vnoremap <silent> <Plug>(flap-dec)   :<C-U>call flap#vflap(-v:count1, 0)<CR>
vnoremap <silent> <Plug>(flap-dec-g) :<C-U>call flap#vflap(-v:count1, 1)<CR>

let &cpo = s:save_cpo
unlet s:save_cpo
