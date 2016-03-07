
function! github_complete#error(msg)
    echohl ErrorMsg
    echomsg 'github-complete.vim: ' . a:msg
    echohl None
endfunction

function! github_complete#find_start(input, pattern, completion)
    if !g:github_complete_enable_{a:completion}_completion
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
    let cached = g:github_complete_enable_api_cache ? '_cached' : ''
    let sync = a:0 == 0 || !a:1 || !s:P.has_vimproc() ? 'sync' : 'async'

    return github_complete#api#call_{sync}{cached}(a:path, a:param)
endfunction


function! s:find_start_col()
    let line = getline('.')
    let s:completion_kind = ''

    for kind in ['emoji', 'issue', 'user', 'repo', 'link']
        let c = github_complete#{kind}#find_start(line)
        if c >= 0
            let s:completion_kind = kind
            return c
        endif
    endfor

    if g:github_complete_fallback_omnifunc != ''
        " Note: findstart and base are always 1 and '' here.
        return call(g:github_complete_fallback_omnifunc, [1, ''])
    endif

    return col('.') - 1
endfunction

function! github_complete#complete(findstart, base)
    if a:findstart
        return s:find_start_col()
    endif

    if index(['emoji', 'issue', 'user', 'repo', 'link'], s:completion_kind) >= 0
        return github_complete#{s:completion_kind}#candidates(a:base)
    endif

    if g:github_complete_fallback_omnifunc != ''
        return call(g:github_complete_fallback_omnifunc, [a:findstart, a:base])
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

function! github_complete#manual_complete()
    let idx = s:find_start_col()
    if idx < 0
        return ''
    endif
    let col = idx + 1
    let base = getline('.')[idx : col('.')-1]
    call complete(col, github_complete#complete(0, base))
    return ''
endfunction
