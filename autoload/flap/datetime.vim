" File:        autoload/flap/datetime.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2020-09-09
" License:     MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:spec = {
\  'H': '2\[0-3]\|\[ 0-1]\=\d',
\  'I': '1\[0-2]\|\[ 0]\=\[1-9]',
\  'M': '\[ 0-5]\=\d',
\  'p': '\[AP]M',
\  'S': '60\|\[ 0-5]\=\d',
\}

function! flap#datetime#rule(format) abort
  let g = []
  let n = 0
  let i = 0
  while 1
    let m = matchstrpos(a:format, '%\zs.', i)
    if m[0] ==# ''
      if i < len(a:format)
        let g += [['', s:escape(a:format[i :])]]
      endif
      break
    elseif m[1] - i >= 2
      let g += [['', s:escape(a:format[i : m[1]-2])]]
    endif

    if has_key(s:spec, m[0])
      let g += [[m[0], s:spec[m[0]]]]
      let n += 1
    elseif m[0] ==# '%'
      let g += [['', '%']]
    else
      throw printf("flap: datetime: unknown specifier '%%%s'", m[0])
    endif
    let i = m[2]
  endwhile
  return [{
  \  'pattern': '\V' . s:pattern(copy(g)),
  \  'groups':  g,
  \  'n':       n,
  \  'replace': function('s:datetime'),
  \}]
endfunction

function! s:datetime(rule, match, count) abort
  let [time, char] = s:parse(a:rule, a:match)

  if char =~# '[Ip]'
    let char = 'H'
  endif
  let time[char] += a:count

  let s = time.H * 3600 + time.M * 60 + time.S
  while s < 0
    let s += 86400
  endwhile
  let time.H = s / 3600 % 24
  let time.M = s / 60 % 60
  let time.S = s % 60

  return s:format(a:rule, time)
endfunction

function! s:escape(s) abort
  return escape(a:s, '\')
endfunction

function! s:format(rule, time) abort
  let s = ''
  for g in a:rule.groups
    if g[0] ==# ''
      let s .= g[1]
    elseif g[0] ==# 'p'
      let s .= a:time.H < 12 ? 'AM' : 'PM'
    else
      if g[0] ==# 'I'
        let I = a:time.H % 12
        let a:time.I = I != 0 ? I : 12
      endif
      let s .= printf('%02d', a:time[g[0]])
    endif
  endfor
  return s
endfunction

function! s:pattern(list) abort
  return join(map(a:list, "v:val[0] ==# '' ? v:val[1] : '\\%(' . v:val[1] . '\\)'"), '')
endfunction

function! s:parse(rule, match) abort
  let time = {'H': 0, 'M': 0, 'S': 0}
  let char = ''

  let pos = col('.') - 1 - a:match[1]
  let n = a:rule.n
  let i = 0
  let j = 0
  while n > 0
    let g = a:rule.groups[i]
    let i += 1
    if g[0] ==# ''
      continue
    endif

    let pat = '\V\%(' . g[1] . '\)\ze' . s:pattern(copy(a:rule.groups[i :])) . '\$'
    let m = matchstrpos(a:match[0], pat, j)
    if g[0] ==# 'p'
      let time.p = m[0]
    else
      let time[g[0]] = str2nr(m[0])
    endif
    if j <= pos && pos < m[2]
      let char = g[0]
    endif
    let j = m[2]
    let n -= 1
  endwhile
  " 12h -> 24h
  if has_key(time, 'I')
    let time.H = remove(time, 'I') % 12
    if has_key(time, 'p') && remove(time, 'p') ==# 'PM'
      let time.H += 12
    endif
  endif
  return [time, char]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
