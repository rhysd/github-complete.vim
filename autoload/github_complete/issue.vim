let s:save_cpo = &cpo
set cpo&vim

let [s:P, s:H, s:J] = github_complete#import_vital()

let s:cache = {}

" From open-browser-github.vim
" Copyright (c) 2013, tyru
"  All rights reserved.
function! s:git(...) " {{{
    let cmd = [g:github_complete#git_cmd] + a:000
    let output = s:P.system(cmd)
    if s:P.get_last_status()
        call github_complete#error("failed '" . join(cmd, ' ') . "' (exited with " . s:P.get_last_status() . ")")
        return ''
    endif
    return output
endfunction

function! s:parse_github_remote_url(github_host)
    let host_re = escape(a:github_host, '.')
    let gh_host_re = 'github\.com'

    " ex) ssh_re_fmt also supports 'ssh://' protocol. (#10)
    " - git@github.com:tyru/open-github-browser.vim
    " - ssh://git@github.com/tyru/open-github-browser.vim
    let ssh_re_fmt = 'git@%s[:/]\([^/]\+\)/\([^/]\+\)\s'
    let git_re_fmt = 'git://%s/\([^/]\+\)/\([^/]\+\)\s'
    let https_re_fmt = 'https\?://%s/\([^/]\+\)/\([^/]\+\)\s'

    let ssh_re = printf(ssh_re_fmt, host_re)
    let git_re = printf(git_re_fmt, host_re)
    let https_re = printf(https_re_fmt, host_re)

    let gh_ssh_re = printf(ssh_re_fmt, gh_host_re)
    let gh_git_re = printf(git_re_fmt, gh_host_re)
    let gh_https_re = printf(https_re_fmt, gh_host_re)

    let matched = []

    for line in split(s:git('remote', '-v'), '\n', 1)
        " Even if host is not 'github.com',
        " parse also 'github.com'.
        for re in [ssh_re, git_re, https_re] +
        \   (a:github_host !=# 'github.com' ?
        \       [gh_ssh_re, gh_git_re, gh_https_re] : [])
            let m = matchlist(line, re)
            if !empty(m)
                return {
                \   'user': m[1],
                \   'name': substitute(m[2], '\.git$', '', ''),
                \ }
            endif
        endfor
    endfor
    return ''
endfunction
" }}}

function! s:call_api(user, repo)
    let response = s:H.request({
        \ 'url' : 'https://api.github.com/repos/rhysd/Dachs/issues',
        \ 'headers' : {'Accept' : 'application/vnd.github.v3+json'},
        \ 'method' : 'GET',
        \ 'param' : {'state' : 'all', 'per_page' : g:neocomplete#sources#github_issue#num_candidates},
        \ 'client' : ['curl', 'wget'],
        \ })
    if !response.success
        call github_complete#error('API request was failed with status' . response.status . ': ' . response.statusText)
        return []
    endif
    return s:J.decode(response.content)
endfunction

function! s:issues(user, repo)
    let path = a:user . '/' . a:repo
    if has_key(s:cache, path)
        return s:cache[path]
    endif

    let candidates = map(s:call_api(a:user, a:repo), '{
                \ "number" : v:val.number,
                \ "title" : v:val.title,
                \ }')
    let s:cache[path] = candidates

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
    if a:0 == 0
        let s:cache = {}
    elseif (has_key(s:cache, a:1))
        unlet s:cache[a:1]
    endif
endfunction

function! github_complete#issue#candidates(base)
    if !g:github_complete#enable_issue_completion
        return []
    endif

    let repo = s:parse_github_remote_url("github.com")

    let candidates = s:issues(repo.user, repo.name)

    return map(copy(candidates), '{
                \ "word" : "#" . (g:github_complete#include_issue_title ? v:val.number . " " . v:val.title : v:val.number),
                \ "abbr" : "#" . v:val.number . " " . v:val.title,
                \ "menu" : "[issue]",
                \ }')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

