
let s:vital = github_complete#import_vital()
let s:P = s:vital['Process']

" From open-browser-github.vim
" Copyright (c) 2013, tyru
"  All rights reserved.
function! s:git(...)
    let cmd = [g:github_complete_git_cmd] + a:000
    let output = s:P.system(cmd)
    if s:P.get_last_status()
        call github_complete#error("failed '" . join(cmd, ' ') . "' (exited with " . s:P.get_last_status() . ")")
        return ''
    endif
    return output
endfunction

function! github_complete#git#detect_github_repo(github_host)
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
    return {}
endfunction
