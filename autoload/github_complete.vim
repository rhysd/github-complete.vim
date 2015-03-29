function! github_complete#error(msg)
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

function! github_complete#import_vital()
    if !exists('s:modules')
        let vital = vital#of('neco_github')
        let s:modules = map(['Process', 'Web.HTTP', 'Web.JSON'], 'vital.import(v:val)')
    endif
    return s:modules
endfunction

function! github_complete#complete(findstart, base)
    echom a:findstart
    echom a:base
    return []
endfunction
