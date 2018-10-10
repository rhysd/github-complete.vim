let s:save_cpo = &cpo
set cpo&vim

function! s:api_path_and_param(query)
    let api = 'search/repositories'
    let param = 'q=' . a:query . '+in:name&sort=stars'
    return [api, param]
endfunction

function! s:repos(query, async)
    let [path, params] = s:api_path_and_param(a:query)

    let ret = github_complete#call_api(path, params, a:async)
    let response = type(ret) == type({}) ? ret.items : ret

    return map(copy(response), 'v:val.html_url')
endfunction

function! s:gather_candidates(base, async) abort
    if !g:github_complete_enable_link_completion
        return []
    endif

    let m = matchstr(a:base, '\[\zs.\+\ze]\%(: \|(\)$')
    if m ==# ''
        return []
    endif

    let candidates = s:repos(m, a:async)

    return map(candidates, '{
                \ "word" : a:base . v:val,
                \ "menu" : "[link]",
                \ }')
endfunction

function! github_complete#link#find_start(input)
    return github_complete#find_start(a:input, '\[[^]]\{-1,}]\%(: \|(\)$', 'link')
endfunction

function! github_complete#link#candidates(base)
    return s:gather_candidates(a:base, 0)
endfunction

function! github_complete#link#candidates_async(base)
    return s:gather_candidates(a:base, 1)
endfunction

function! github_complete#link#reset_cache(param)
    call github_complete#api#reset_cache('search/repositories', a:param)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
