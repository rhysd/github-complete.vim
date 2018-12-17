let s:save_cpo = &cpo
set cpo&vim

function! s:api_issue_path_and_param(user, repo)
    let api = printf('repos/%s/%s/issues', a:user, a:repo)
    let params = g:github_complete_issue_request_params

    if g:github_complete_max_issue_candidates > 0
      let params['per_page'] = g:github_complete_max_issue_candidates
    endif

    return [api, params]
endfunction

function! s:issues(user, repo, async)
    let [path, params] = s:api_issue_path_and_param(a:user, a:repo)

    let candidates = map(github_complete#call_api(path, params, a:async), '{
                \ "number" : v:val.number,
                \ "title" : v:val.title,
                \ }')

    return candidates
endfunction

function! github_complete#issue#find_start(input)
    return github_complete#find_start(a:input, '#\d*$', 'issue')
endfunction

function! github_complete#issue#reset_cache(...)
    call call('github_complete#api#reset_cache', a:000)
endfunction

function! s:gather_candidates(base, async)
    if !g:github_complete_enable_issue_completion
        return []
    endif

    let repo = github_complete#git#detect_github_repo(s:get_github_repo())
    if empty(repo)
        call github_complete#error('No github repository is found in current directory')
        return []
    endif

    let candidates = filter(copy(s:issues(repo.user, repo.name, a:async)),
                    \ 'stridx("#" . v:val.number, a:base) == 0')

    return map(candidates, '{
                \ "word" : "#" . (g:github_complete_include_issue_title ? v:val.number . " " . v:val.title : v:val.number),
                \ "abbr" : "#" . v:val.number . " " . v:val.title,
                \ "menu" : "[issue]",
                \ }')
endfunction

function! github_complete#issue#candidates(base)
    return s:gather_candidates(a:base, 0)
endfunction

function! github_complete#issue#candidates_async(base)
    return s:gather_candidates(a:base, 1)
endfunction

function! github_complete#issue#fetch_issues()
    let repo = github_complete#git#detect_github_repo(s:get_github_repo())
    if empty(repo)
        return
    endif

    let [path, params] = s:api_issue_path_and_param(repo.user, repo.name)

    " Note: '1' means 'consider cache'
    call github_complete#api#fetch_call_async(path, params, 1)
endfunction

function! s:get_github_repo()
    if g:github_complete_ghe_host !=# ''
        return g:github_complete_ghe_host
    endif

    return 'github.com'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

