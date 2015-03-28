let s:save_cpo = &cpo
set cpo&vim

function! s:error(msg)
    echohl ErrorMsg
    execute 'echomsg' a:msg
    echohl None
endfunction

function! s:has_vim_emoji()
    if !exists('s:exists_vim_emoji')
        try
            call emoji#available()
            let s:exists_vim_emoji = 1
        catch
            let s:exists_vim_emoji = 0
        endtry
    endif
    return s:exists_vim_emoji
endfunction

let s:source = {
\ 'name'      : 'github',
\ 'rank'      : 200,
\ 'kind'      : 'manual',
\ 'filetypes' : { 'markdown' : 1, 'gitcommit' : 1 },
\ }

function! s:source.get_complete_position(context)
    echom a:context.input
    let colon_idx = strridx(a:context.input[:col('.')-1], ':')
    if colon_idx == -1
        echom "foo!"
        return -1
    endif
    echom string(colon_idx)
    return colon_idx
endfunction

function! s:source.gather_candidates(context)
    if emoji#available()
        return
            \ map(emoji#list(), '{
                    \ "word" : ":" . v:val . ":",
                    \ "abbr" : ":" . v:val . ": " . emoji#for(v:val),
                    \ "menu" : "[github]",
                    \ }')
    else
        return map(emoji#list(), '{"word" : ":" . v:val . ":", "menu" : "[github]"}')
    endif
endfunction

function! neocomplete#sources#github#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
