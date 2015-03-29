let g:github_complete#overwrite_completefunc  = get(g:, 'github_complete#overwrite_completefunc', 1)
let g:github_complete#enable_neocomplete      = get(g:, 'github_complete#enable_neocomplete', 0)
let g:github_complete#enable_emoji_completion = get(g:, 'github_complete#enable_emoji_completion', 1)
let g:github_complete#enable_issue_completion = get(g:, 'github_complete#enable_issue_completion', 1)
let g:github_complete#include_issue_title     = get(g:, 'github_complete#include_issue_title', 0)
let g:github_complete#max_issue_candidates    = get(g:, 'github_complete#max_issue_candidates', 100)
let g:github_complete#git_cmd                 = get(g:, 'github_complete#git_cmd', 'git')

function! github_complete#error(msg)
    echohl ErrorMsg
    echomsg 'github-complete.vim: ' . a:msg
    echohl None
endfunction

function! github_complete#import_vital()
    if !exists('s:modules')
        let vital = vital#of('github_complete')
        let s:modules = map(['Process', 'Web.HTTP', 'Web.JSON'], 'vital.import(v:val)')
    endif
    return s:modules
endfunction

function! s:find_start_col()
    let line = getline('.')

    let c = github_complete#emoji#find_start(line)
    if c >= 0
        return c
    endif

    let c = github_complete#issue#find_start(line)
    echom c
    if c >= 0
        return c
    endif

    return col('.') - 1
endfunction

function! github_complete#complete(findstart, base)
    if a:findstart
        return s:find_start_col()
    endif

    for kind in ['emoji', 'issue']
        if github_complete#{kind}#is_available(a:base)
            return github_complete#{kind}#candidates(a:base)
        endif
    endfor

    let candidates = []
    for kind in ['emoji', 'issue']
        let candidates += github_complete#{kind}#candidates(a:base)
    endfor
    return candidates
endfunction
