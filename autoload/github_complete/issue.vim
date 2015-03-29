let s:save_cpo = &cpo
set cpo&vim

function! s:issues(user, repo)
    let path = a:user . '/' . a:repo
    let api = printf('repos/%s/%s/issues', a:user, a:repo)
    let params = {'state' : 'all', 'per_page' : g:github_complete#max_issue_candidates}

    let candidates = map(github_complete#api#call_async_cached(api, params), '{
                \ "number" : v:val.number,
                \ "title" : v:val.title,
                \ }')

    return candidates
endfunction

function! github_complete#issue#find_start(input)
    if !g:github_complete#enable_issue_completion
        return -1
    endif
    return match(a:input[:col('.') - 1], '#\d*$')
endfunction

function! github_complete#issue#is_available(base)
    return a:base =~# '^#\d*$'
endfunction

function! github_complete#issue#reset_cache(...)
    call call('github_complete#api#reset_cache', a:000)
endfunction

function! github_complete#issue#candidates(base)
    if !g:github_complete#enable_issue_completion
        return []
    endif

    let repo = github_complete#git#detect_github_repo("github.com")

    let candidates = s:issues(repo.user, repo.name)

    return map(copy(candidates), '{
                \ "word" : "#" . (g:github_complete#include_issue_title ? v:val.number . " " . v:val.title : v:val.number),
                \ "abbr" : "#" . v:val.number . " " . v:val.title,
                \ "menu" : "[issue]",
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

