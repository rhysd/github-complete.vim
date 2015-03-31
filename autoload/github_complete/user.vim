let s:save_cpo = &cpo
set cpo&vim

function! s:api_path_and_param(query)
    let api = 'search/users'
    let param = 'q=' . a:query . '+in:login'
    return [api, param]
endfunction

function! github_complete#user#find_start(input)
    return github_complete#find_start(a:input, '@\w\+$', 'user')
endfunction

function! s:users(query, async)
    let [path, params] = s:api_path_and_param(a:query)

    let func = a:async ?
                \ 'github_complete#api#call_async_cached' :
                \ 'github_complete#api#call_cached'

    let ret = call(func, [path, params])
    let response = type(ret) == type({}) ? ret.items : ret
    return map(copy(response), '"@" . v:val.login')
endfunction

function! s:gather_candidates(base, async)
    if !g:github_complete#enable_user_completion
        return []
    endif

    let query = a:base =~# '^@' ? a:base[1:] : a:base

    if query ==# ''
        return []
    endif

    let candidates = filter(s:users(query, a:async), 'stridx(v:val, a:base) == 0')

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

function! github_complete#issue#reset_cache()
    call github_complete#api#reset_cache('search/users')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
