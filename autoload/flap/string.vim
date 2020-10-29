" File:        autoload/flap/string.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2020-10-29
" License:     MIT License

let s:save_cpo = &cpo
set cpo&vim

function! flap#string#case(...) abort
  let case = deepcopy(s:case)
  for sty in a:000
    let sty = tolower(sty)
    if sty ==# 'camel'
      let case.pattern .= '\l[0-9a-z]*\%(\u\+[0-9a-z]*\)\+'
    elseif sty ==# 'pascal'
      let case.pattern .= '\%(\u\+\u[0-9a-z]\+\|\u[0-9a-z]\+\u\+[0-9a-z]*\)\%(\u\+[0-9a-z]*\)*'
    elseif sty ==# 'snake'
      let case.pattern .= '\l[0-9a-z]*\%(_[0-9a-z]\+\)\+'
    elseif sty ==# 'kebab'
      let case.pattern .= '\l[0-9a-z]*\%(-[0-9a-z]\+\)\+'
    elseif sty ==# 'cobol'
      let case.pattern .= '\u[0-9A-Z]*\%(-[0-9A-Z]\+\)\+'
    elseif sty =~# '^screaming[-_ ]snake$'
      let case.pattern .= '\u[0-9A-Z]*\%(_[0-9A-Z]\+\)\+'
      let sty = 'screaming_snake'
    elseif sty =~# '^http[-_ ]header$'
      let case.pattern .= '\u\+[0-9a-z]*\%(-\u\+[0-9a-z]*\)\+'
      let sty = 'http_header'
    else
      throw printf("flap: string: unknown case style '%s'", sty)
    endif
    let case.pattern .= '\|'
    let case.order   += [sty]
  endfor
  let case.pattern = case.pattern[: -3]
  return [case]
endfunction

let s:case = {
\  'pattern': '',
\  'order':   [],
\}

function! s:case.replace(rule, match, count) abort
  " parse
  if stridx(a:match[0], '-') != -1
    let sty  = a:match[0] =~# '^\l' ? 'kebab' : a:match[0] =~# '\l' ? 'http_header' : 'cobol'
    let list = split(a:match[0], '-')
  elseif stridx(a:match[0], '_') != -1
    let sty  = a:match[0] =~# '^\l' ? 'snake' : 'screaming_snake'
    let list = split(a:match[0], '_')
  else
    let sty  = a:match[0] =~# '^\l' ? 'camel' : 'pascal'
    let list = split(a:match[0], '\ze\u\l\|\l\zs\ze\u')
  endif
  " convert
  let n = len(self.order)
  return self[self.order[(n+a:count+index(self.order, sty))%n]](list)
endfunction

function! s:case.camel(list) abort
  return join(map(a:list, 'v:key == 0 ? tolower(v:val) : s:totitle(v:val)'), '')
endfunction

function! s:case.cobol(list) abort
  return toupper(join(a:list, '-'))
endfunction

function! s:case.http_header(list) abort
  return join(map(a:list, 's:totitle(v:val)'), '-')
endfunction

function! s:case.kebab(list) abort
  return tolower(join(a:list, '-'))
endfunction

function! s:case.pascal(list) abort
  return join(map(a:list, 's:totitle(v:val)'), '')
endfunction

function! s:case.screaming_snake(list) abort
  return toupper(join(a:list, '_'))
endfunction

function! s:case.snake(list) abort
  return tolower(join(a:list, '_'))
endfunction

function! s:totitle(s) abort
  return toupper(strcharpart(a:s, 0, 1)) . tolower(strcharpart(a:s, 1))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
