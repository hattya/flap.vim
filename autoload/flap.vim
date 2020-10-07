" File:        autoload/flap.vim
" Author:      Akinori Hattori <hattya@gmail.com>
" Last Change: 2020-10-07
" License:     MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:greedy = 0

function! flap#nflap(count) abort
  try
    let s:greedy = 0
    let l = getline('.')
    let best = s:best_match(l, s:rules(), col('.') - 1, len(l))
  catch
    return s:error(v:exception)
  endtry

  if !empty(best.match)
    let v = s:setline('.', l, best, a:count)
    call setpos("'[", [0, line('.'), best.match[1] + 1, 0])
    call setpos("']", [0, line('.'), best.match[1] + len(v), 0])
  else
    execute printf('normal! %d%s', abs(a:count), a:count >= 0 ? "\<C-A>" : "\<C-X>")
  endif
endfunction

function! flap#vflap(count, g) abort
  normal! gv
  let lhs = getpos("'<")
  let rhs = getpos("'>")

  try
    let rules = s:rules()
    let cl = {}
    let lnum = lhs[1]
    let start = lhs[2] - 1
    let end = &selection ==# 'exclusive' ? rhs[2] - 1 : rhs[2]
    if mode() ==# 'v'
      if start < end
        let s:greedy = 0
        while lnum < rhs[1]
          let l = getline(lnum)
          let best = s:best_match(l, rules, start, len(l))
          if !empty(best.match)
            let cl[lnum] = [l, best]
          endif
          let lnum += 1
          let start = 0
        endwhile
        let l = getline(lnum)
        let best = s:best_match(l, rules, start, end)
        if !empty(best.match)
          let cl[lnum] = [l, best]
        endif
      endif
    elseif mode() ==# 'V'
      let s:greedy = 0
      while lnum <= rhs[1]
        let l = getline(lnum)
        let best = s:best_match(l, rules, start, end)
        if !empty(best.match)
          let cl[lnum] = [l, best]
        endif
        let lnum += 1
      endwhile
    elseif mode() ==# "\<C-V>"
      if start < end
        let s:greedy = 1
        while lnum <= rhs[1]
          let l = getline(lnum)
          let best = s:best_match(l, rules, start, end)
          if !empty(best.match)
            let cl[lnum] = [l, best]
          endif
          let lnum += 1
        endwhile
      endif
    endif
  catch
    return s:error(v:exception)
  endtry

  let key = a:count >= 0 ? "\<C-A>" : "\<C-X>"
  if !empty(cl)
    " save
    let visual = [mode(), getpos("'<"), getpos("'>")]
    execute "normal! \<Esc>"

    call setpos("']", repeat([0], 4))
    let lnum = lhs[1]
    let start = lhs[2] - 1
    let i = 1
    while lnum <= rhs[1]
      if has_key(cl, lnum)
        let [l, best] = cl[lnum]
        let v = s:setline(lnum, l, best, a:count * i)
        let rhs[2] = start + len(v)
        let i += !!a:g
      elseif col([lnum, '$']) > 1
        call cursor(lnum, start + 1)
        execute printf("normal! v0%dl%d%s", end - 1, abs(a:count * i), key)
        let i += a:g && getpos("']")[1] == lnum
      endif
      let lnum += 1
      if visual[0] ==# 'v'
        let start = 0
      endif
    endwhile
    call setpos('.', lhs)
    call setpos("'[", lhs)
    if has_key(cl, rhs[1])
      call setpos("']", rhs)
    endif
    " restore
    execute printf("normal! %s\<Esc>", visual[0])
    call setpos("'<", visual[1])
    call setpos("'>", visual[2])
  else
    execute printf('normal! %d%s%s', abs(a:count), a:g ? 'g' : '', key)
  endif
endfunction

function! s:rules() abort
  let rules = []
  for d in [b:, g:]
    if has_key(d, 'flap')
      call extend(rules, get(d.flap, 'rules', []))
    endif
  endfor
  return rules
endfunction

function! s:best_match(s, rules, start, end) abort
  let best = {'index': -1, 'match': [], 'rule': []}
  for rule in a:rules
    let [i, m] = s:match(a:s, rule, a:start, a:end)
    if s:cmp(m, best.match) < 0
      let best.index = i
      let best.match = m
      let best.rule = rule
    endif
  endfor
  return best
endfunction

function! s:match(s, rule, start, end) abort
  " compile rule
  let pat = '\V\C\%('
  for v in a:rule
    if type(v) is v:t_string
      let pat .= escape(v, '\')
    elseif type(v) is v:t_dict
      let pat .= '\m\%(' . v.pattern . '\)\V'
    else
      throw 'invalid rule: ' . string(a:rule)
    endif
    let pat .= '\|'
  endfor
  let pat = pat[: -2] . ')'
  " match
  let rv = [-1, []]
  let start = 0
  while start <= a:end
    let m = matchstrpos(a:s, pat, start)
    if m[0] ==# ''
      break
    elseif m[1] <= a:start && a:start < m[2] && m[2] <= a:end
      let i = 0
      for v in a:rule
        if type(v) is v:t_string
          let pat = '\V\C' . escape(v, '\')
        else
          let pat = '\C' . v.pattern
        endif
        let x = matchstrpos(a:s, pat, m[1])
        if x[1] <= a:start && a:start < x[2] && x[2] <= a:end && s:cmp(x, rv[1]) < 0
          let rv = [i, x]
        endif
        let i += 1
      endfor
      break
    endif
    let start = m[2]
  endwhile
  return rv
endfunction

function! s:cmp(a, b) abort
  if empty(a:a)
    return empty(a:b) ? 0 : 1
  elseif empty(a:b)
    return -1
  endif

  if a:a[1] != a:b[1]
    " nearer
    let v = a:b[1] - a:a[1]
  else
    " shorter
    let v = a:a[2] - a:b[2]
  endif
  return s:greedy ? -v : v
endfunction

function! s:error(msg) abort
  redraw
  echohl ErrorMsg
  echomsg 'flap: ' . a:msg
  echohl None
endfunction

function! s:setline(lnum, s, best, count) abort
  if type(a:best.rule[a:best.index]) is v:t_dict && type(a:best.rule[a:best.index].replace) is v:t_func
    let v = a:best.rule[a:best.index].replace(a:best.rule[a:best.index], a:best.match, a:count)
  else
    let n = len(a:best.rule)
    let v = a:best.rule[(n+a:count+a:best.index)%n]
    if type(v) is v:t_dict
      let v = substitute(a:best.match[0], '\C' . a:best.rule[a:best.index].pattern, v.replace, '')
    endif
  endif
  call setline(a:lnum, (a:best.match[1] > 0 ? a:s[: a:best.match[1]-1] : '') . v . a:s[a:best.match[2] :])
  return v
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
