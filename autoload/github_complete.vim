let g:github_complete#enable_emoji_completion = get(g:, 'github_complete#enable_emoji_completion', 1)

function! github_complete#error(msg)
    echohl ErrorMsg
    echomsg a:msg
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
    if g:github_complete#enable_emoji_completion
        if c >= 0
            return c
        endif
    endif
    return col('.') - 1
endfunction

function! github_complete#complete(findstart, base)
    if a:findstart
        return s:find_start_col()
    endif

    let candidates = []

    if g:github_complete#enable_emoji_completion
        let candidates += github_complete#emoji#candidates(a:base)
    endif
    return candidates
endfunction
