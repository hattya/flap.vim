" File:        autoload/flap.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2019-09-23
" License:     MIT License

let s:save_cpo = &cpo
set cpo&vim

function! flap#ninc(count) abort
  return s:nflap(a:count)
endfunction

function! flap#ndec(count) abort
  return s:nflap(-a:count)
endfunction

function! s:nflap(count) abort
  let l = getline('.')
  let best = s:best_match(l)
  if !empty(best.match)
    let pfx = best.match[1] > 0 ? l[: best.match[1]-1] : ''
    let v = best.rule[(len(best.rule)+a:count+best.index)%len(best.rule)]
    call setline('.', pfx . v . l[best.match[2] :])
    call setpos("'[", [0, line('.'), best.match[1] + 1, 0])
    call setpos("']", [0, line('.'), best.match[1] + len(v), 0])
  else
    execute printf('normal! %d%s', abs(a:count), a:count >= 0 ? "\<C-A>" : "\<C-X>")
  endif
endfunction

function! s:best_match(line) abort
  let rules = []
  for d in [b:, g:]
    if has_key(d, 'flap')
      call extend(rules, get(d.flap, 'rules', []))
    endif
  endfor
  let best = {'index': -1, 'match': [], 'rule': []}
  for rule in rules
    let [i, m] = s:match(a:line, rule)
    if s:cmp(m, best.match) < 0
      let best.index = i
      let best.match = m
      let best.rule = rule
    endif
  endfor
  return best
endfunction

function! s:match(line, rule) abort
  let col = col('.') - 1
  " compile rule
  let pat = '\V\C\%('
  for v in a:rule
    if type(v) is v:t_string
      let pat .= escape(v, '\')
    else
      throw 'invalid rule: ' . string(a:rule)
    endif
    let pat .= '\|'
  endfor
  let pat = pat[: -2] . ')'
  " match
  let start = 0
  while start <= col
    let m = matchstrpos(a:line, pat, start)
    if m[0] ==# ''
      break
    elseif m[1] <= col && col < m[2]
      let start = m[1]
      let rv = [-1, []]
      let i = 0
      for v in a:rule
        let pat = '\V\C' . escape(v, '\')
        let x = matchstrpos(a:line, pat, start)
        if x[1] <= col && col < x[2] && s:cmp(x, rv[1]) < 0
          let rv = [i, x]
        endif
        let i += 1
      endfor
      return rv
    endif
    let start = m[2]
  endwhile
  return [-1, []]
endfunction

function! s:cmp(a, b) abort
  if empty(a:a)
    return empty(a:b) ? 0 : 1
  elseif empty(a:b)
    return -1
  endif

  if a:a[1] != a:b[1]
    " nearer
    return a:b[1] - a:a[1]
  else
    " shorter
    return a:a[2] - a:b[2]
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
