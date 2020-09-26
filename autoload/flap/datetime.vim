" File:        autoload/flap/datetime.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2020-09-26
" License:     MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:A = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
let s:a = map(copy(s:A), 'v:val[: 2]')
let s:B = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
let s:b = map(copy(s:B), 'v:val[: 2]')

let s:spec = {
\  'A': join(s:A, '\|'),
\  'a': join(s:a, '\|'),
\  'B': join(s:B, '\|'),
\  'b': join(s:b, '\|'),
\  'd': '3\[0-1]\|\[1-2]\d\|\[ 0]\=\[1-9]',
\  'H': '2\[0-3]\|\[ 0-1]\=\d',
\  'I': '1\[0-2]\|\[ 0]\=\[1-9]',
\  'M': '\[ 0-5]\=\d',
\  'm': '1\[0-2]\|\[ 0]\=\[1-9]',
\  'p': '\[AP]M',
\  'S': '60\|\[ 0-5]\=\d',
\  'Y': '\d\{4,1}',
\  'y': '\d\d',
\  'z': '\[+-]\d\d:\=\d\d',
\}
let s:dest = {
\  'A': 'd',
\  'a': 'd',
\  'B': 'm',
\  'b': 'm',
\  'I': 'H',
\  'p': 'H',
\  'y': 'Y',
\}

let s:max_tz =  14 * 60
let s:min_tz = -12 * 60

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

  if char ==# 'z'
    let z = time.z[0] + a:count * 15
    while z < s:min_tz
      let z += s:max_tz + 60 - s:min_tz
    endwhile
    while z > s:max_tz
      let z += s:min_tz - 60 - s:max_tz
    endwhile
    let time.z[0] = z
  else
    let char = get(s:dest, char, char)
    let time[char] += a:count
    if char ==# 'm'
      while time.m < 1
        let time.Y -= 1
        let time.m += 12
      endwhile
      while time.m > 12
        let time.Y += 1
        let time.m -= 12
      endwhile
    elseif char =~# '[HMS]'
      let s = time.H * 3600 + time.M * 60 + time.S
      while s < 0
        let time.d -= 1
        let s += 86400
      endwhile
      while s >= 86400
        let time.d += 1
        let s -= 86400
      endwhile
      let time.H = s / 3600 % 24
      let time.M = s / 60 % 60
      let time.S = s % 60
    endif
    let m = time.m
    call extend(time, s:date(s:julian_day(time.Y, time.m, time.d)))
    if char ==# 'm' && time.m != m
      call extend(time, s:date(s:julian_day(time.Y, time.m, time.d) - time.d))
    endif
  endif

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
    elseif g[0] =~? 'A'
      let s .= get(s:, g[0])[s:week_day(s:julian_day(a:time.Y, a:time.m, a:time.d))]
    elseif g[0] =~? 'B'
      let s .= get(s:, g[0])[a:time.m-1]
    elseif g[0] ==# 'p'
      let s .= a:time.H < 12 ? 'AM' : 'PM'
    elseif g[0] ==# 'z'
      let [z, sep] = a:time.z
      if z < 0
        let z = -z
        let sign = '-'
      else
        let sign = '+'
      endif
      let s .= printf('%s%02d%s%02d', sign, z / 60, sep, z % 60)
    else
      if g[0] ==# 'I'
        let I = a:time.H % 12
        let a:time.I = I != 0 ? I : 12
      elseif g[0] ==# 'y'
        let a:time.y = a:time.Y % 100
      endif
      let s .= printf('%0*d', g[0] ==# 'Y' ? 0 : 2, a:time[g[0]])
    endif
  endfor
  return s
endfunction

function! s:date(j) abort
  let f = a:j + 1401 + (4 * a:j + 274277) / 146097 * 3 / 4 - 38
  let e = 4 * f + 3
  let g = e % 1461 / 4
  let h = 5 * g + 2
  let D = h % 153 / 5 + 1
  let M = (h / 153 + 2) % 12 + 1
  let Y = e / 1461 - 4716 + (12 + 2 - M) / 12
  return {'Y': Y, 'm': M, 'd': D}
endfunction

function! s:julian_day(y, m, d) abort
  let y = a:y + 4800 - (a:m <= 2)
  let m = a:m + (a:m <= 2 ? 9 : -3)
  return a:d + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
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
    if g[0] =~? 'A'
      let time.w = index(get(s:, g[0]), m[0])
    elseif g[0] =~? 'B'
      let time.m = index(get(s:, g[0]), m[0]) + 1
    elseif g[0] ==# 'p'
      let time.p = m[0]
    elseif g[0] ==# 'y'
      let time.Y = m[0] + (m[0] >= 69 ? 1900 : 2000)
    elseif g[0] ==# 'z'
      let time.z = [str2nr(m[0][: 2]) * 60 + str2nr(m[0][3 :]), m[0][3 : -3]]
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

  if has_key(time, 'w')
    let w = remove(time, 'w')
    let t = extend(s:today(), time)
    if s:week_day(s:julian_day(t.Y, t.m, t.d)) != w
      if !has_key(time, 'd')
        let t.d = 7 - s:week_day(s:julian_day(t.Y, t.m, 7)) + w
      elseif !has_key(time, 'm')
      elseif !has_key(time, 'Y')
        while 1
          let t.Y -= 1
          let j = s:julian_day(t.Y, t.m, t.d)
          if s:week_day(j) == w && s:date(j).m == t.m
            break
          endif
        endwhile
      endif
    endif
    let time = t
  else
    call extend(time, s:today(), 'keep')
  endif
  return [time, char]
endfunction

function! s:today() abort
  let d = map(split(strftime('%Y %m %d')), 'str2nr(v:val)')
  return {'Y': d[0], 'm': d[1], 'd': d[2]}
endfunction

function! s:week_day(j) abort
  return (a:j + 1) % 7
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
