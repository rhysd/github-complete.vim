let s:save_cpo = &cpo
set cpo&vim

function! s:api_path_and_param(query)
    let api = 'search/users'
    let param = 'q=' . a:query . '+in:login'
    return [api, param]
endfunction

function! github_complete#user#find_start(input)
    return github_complete#find_start(a:input, '\%(@\|\<github\.com/\zs\)[[:alnum:]-_]\+$', 'user')
endfunction

function! s:users(query, at_matched, async)
    let [path, params] = s:api_path_and_param(a:query)

    let ret = github_complete#call_api(path, params, a:async)
    let response = type(ret) == type({}) ? ret.items : ret
    let prefix = a:at_matched ? "@" : ""

    return map(copy(response), 'prefix . v:val.login')
endfunction

function! s:gather_candidates(base, async)
    if !g:github_complete_enable_user_completion
        return []
    endif

    let at_matched = a:base =~# '^@'

    let query = at_matched ? a:base[1:] : a:base

    if query ==# ''
        return []
    endif

    let candidates = filter(s:users(query, at_matched, a:async), 'stridx(v:val, a:base) == 0')

    return map(candidates, '{
                \ "word" : v:val,
                \ "menu" : "[user]",
                \ }')
endfunction

function! github_complete#user#candidates(base)
    return s:gather_candidates(a:base, 0)
endfunction

function! github_complete#user#candidates_async(base)
    return s:gather_candidates(a:base, 1)
endfunction

function! github_complete#issue#reset_cache(param)
    call github_complete#api#reset_cache('search/users', a:param)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
