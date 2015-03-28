let s:save_cpo = &cpo
set cpo&vim

let g:neocomplete#sources#github_issue#git_cmd = get(g:, 'neocomplete#sources#github_issue#git_cmd', 'git')

let s:source = {
\ 'name'      : 'github_issue',
\ 'rank'      : 200,
\ 'kind'      : 'manual',
\ 'filetypes' : { 'markdown' : 1, 'gitcommit' : 1 },
\ }

function! s:source.get_complete_position(context)
    return strridx(a:context.input[:col('.')-1], '#')
endfunction

" From open-browser-github.vim
" Copyright (c) 2013, tyru
"  All rights reserved.
function! s:git(...) " {{{
    let cmd = [g:neocomplete#sources#github_issue#git_cmd] + a:000
    let output = vimproc#system(cmd)
    if vimproc#get_last_status()
        call neco_github#error("failed '" . join(cmd, ' ') . "' (exited with " . vimproc#get_last_status() . ")")
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
                \   'repos': substitute(m[2], '\.git$', '', ''),
                \ }
            endif
        endfor
    endfor
    return ''
endfunction
" }}}

function! s:source.gather_candidates(context)
    return []
endfunction

function! neocomplete#sources#github_issue#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
