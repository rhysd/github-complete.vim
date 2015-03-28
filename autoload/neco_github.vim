function! neco_github#error(msg)
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

function! neco_github#import_all()
    if !exists('s:modules')
        let vital = vital#of('neco_github')
        let s:modules = map(['Process', 'Web.HTTP', 'Web.JSON'], 'vital.import(v:val)')
    endif
    return s:modules
endfunction
