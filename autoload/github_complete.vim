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
    return github_complete#emoji#find_start()
endfunction

function! github_complete#complete(findstart, base)
    PP! [a:findstart, a:base]
    if a:findstart
        return s:find_start_col()
    endif
    return github_complete#emoji#candidates(a:base)
endfunction
