let s:save_cpo = &cpo
set cpo&vim

let g:neocomplete#sources#github_issue#git_cmd = get(g:, 'neocomplete#sources#github_issue#git_cmd', 'git')
let g:neocomplete#sources#github_issue#include_title = get(g:, 'neocomplete#sources#github_issue#include_title', 0)
let g:neocomplete#sources#github_issue#num_candidates = get(g:, 'neocomplete#sources#github_issue#num_candidates', 100)

let [s:P, s:H, s:J] = github_complete#import_vital()

" Note:
" github_issue controls its cache by itself
let s:source = {
\ 'name'        : 'github_issue',
\ 'rank'        : 200,
\ 'kind'        : 'manual',
\ 'is_volatile' : 1,
\ 'disabled'    : 1,
\ }

let s:cache = {}

function! s:source.get_complete_position(context)
    return strridx(a:context.input[:col('.')-1], '#')
endfunction

" From open-browser-github.vim
" Copyright (c) 2013, tyru
"  All rights reserved.
function! s:git(...) " {{{
    let cmd = [g:neocomplete#sources#github_issue#git_cmd] + a:000
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
                \ "word" : "#" . (g:neocomplete#sources#github_issue#include_title ? v:val.number . " " . v:val.title : v:val.number),
                \ "abbr" : "#" . v:val.number . " " . v:val.title,
                \ "menu" : "[issue]",
                \ }')
    let s:cache[path] = candidates

    return candidates
endfunction

function! s:source.gather_candidates(context)
    let repo = s:parse_github_remote_url("github.com")
    return s:issues(repo.user, repo.name)
endfunction

function! neocomplete#sources#github_issue#define()
    return s:source
endfunction

function! neocomplete#sources#github_issue#reset_cache(...)
    if a:0 == 0
        let s:cache = {}
    elseif (has_key(s:cache, a:1))
        unlet s:cache[a:1]
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
