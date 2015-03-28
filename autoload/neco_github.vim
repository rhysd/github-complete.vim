function! neco_github#error(msg)
    echohl ErrorMsg
    execute 'echomsg' a:msg
    echohl None
endfunction
