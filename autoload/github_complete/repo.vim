let s:save_cpo = &cpo
set cpo&vim

function! s:api_path_and_param(user, query)
    let api = 'search/repositories'
    let param = 'q=' . a:query . '+in:name+user:' . a:user
    return [api, param]
endfunction

function! github_complete#repo#find_start(input)
    return github_complete#find_start(a:input, '[[:alnum:]-_]\+/[[:alnum:]-_]\+$', 'user')
endfunction

function! s:repos(user, query, async)
    let [path, params] = s:api_path_and_param(a:user, a:query)

    let ret = github_complete#call_api(path, params, a:async)
    let response = type(ret) == type({}) ? ret.items : ret

    return map(copy(response), 'v:val.name')
endfunction

function! s:gather_candidates(base, async)
    if !g:github_complete_enable_repo_completion
        return []
    endif

    let m = matchlist(a:base, '\([[:alnum:]-_]\+\)/\([[:alnum:]-_]\+\)')

    let candidates = filter(s:repos(m[1], m[2], a:async), 'stridx(v:val, m[2]) == 0')

    return map(candidates, '{
                \ "word" : m[1] . "/" . v:val,
                \ "menu" : "[repo]",
                \ }')
endfunction

function! github_complete#repo#candidates(base)
    return s:gather_candidates(a:base, 0)
endfunction

function! github_complete#repo#candidates_async(base)
    return s:gather_candidates(a:base, 1)
endfunction

function! github_complete#repo#reset_cache(param)
    call github_complete#api#reset_cache('search/repositories', a:param)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
