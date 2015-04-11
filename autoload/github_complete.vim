
" Variables {{{
function! s:set_global_var(name, default)
    let g:github_complete#{a:name} = get(g:, 'github_complete#' . a:name, a:default)
endfunction

call s:set_global_var('overwrite_omnifunc_filetypes', [])
call s:set_global_var('enable_neocomplete', 0)
call s:set_global_var('enable_emoji_completion', 1)
call s:set_global_var('enable_issue_completion', 1)
call s:set_global_var('enable_user_completion', 1)
call s:set_global_var('enable_repo_completion', 1)
call s:set_global_var('include_issue_title', 0)
call s:set_global_var('max_issue_candidates', 100)
call s:set_global_var('git_cmd', 'git')
call s:set_global_var('fetch_issue_api_filetypes', ['gitcommit'])
call s:set_global_var('emoji_japanese_workaround', 0)
call s:set_global_var('fallback_omnifunc', '')
call s:set_global_var('enable_api_cache', 1)
" }}}

function! github_complete#error(msg)
    echohl ErrorMsg
    echomsg 'github-complete.vim: ' . a:msg
    echohl None
endfunction

function! github_complete#find_start(input, pattern, completion)
    if !g:github_complete#enable_{a:completion}_completion
        return -1
    endif

    let c = col('.')

    if a:input ==# '' || c == 1
        return -1
    endif

    return match(a:input[:c - 2], a:pattern)
endfunction

function! github_complete#import_vital()
    if !exists('s:modules')
        let s:modules = {}
        let vital = vital#of('github_complete')
        for m in ['Process', 'Web.HTTP', 'Web.JSON', 'Data.Optional']
            let s:modules[m] = vital.import(m)
        endfor
    endif

    return s:modules
endfunction

let s:P = github_complete#import_vital()['Process']

function! github_complete#call_api(path, param, ...)
    let cached = g:github_complete#enable_api_cache ? '_cached' : ''
    let sync = a:0 == 0 || !a:1 || !s:P.has_vimproc() ? 'sync' : 'async'

    return github_complete#api#call_{sync}{cached}(a:path, a:param)
endfunction


function! s:find_start_col()
    let line = getline('.')
    let s:completion_kind = ''

    for kind in ['emoji', 'issue', 'user', 'repo']
        let c = github_complete#{kind}#find_start(line)
        if c >= 0
            let s:completion_kind = kind
            return c
        endif
    endfor

    if g:github_complete#fallback_omnifunc != ''
        " Note: findstart and base are always 1 and '' here.
        return call(g:github_complete#fallback_omnifunc, [1, ''])
    endif

    return col('.') - 1
endfunction

function! github_complete#complete(findstart, base)
    if a:findstart
        return s:find_start_col()
    endif

    if index(['emoji', 'issue', 'user', 'repo'], s:completion_kind) >= 0
        return github_complete#{s:completion_kind}#candidates(a:base)
    endif

    if g:github_complete#fallback_omnifunc != ''
        return call(g:github_complete#fallback_omnifunc, [a:findstart, a:base])
    endif

    " Note:
    " Show the result of 'emoji' and 'issue' completion only
    " because 'user' and 'repo' are based on search query.
    " 'base' is an entire line, it can't be a query for the search.
    let candidates = []
    for kind in ['emoji', 'issue']
        let candidates += github_complete#{kind}#candidates(a:base)
    endfor
    return candidates
endfunction

