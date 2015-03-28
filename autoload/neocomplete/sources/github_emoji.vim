let s:save_cpo = &cpo
set cpo&vim

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
\ 'name'      : 'github_emoji',
\ 'rank'      : 200,
\ 'kind'      : 'manual',
\ 'filetypes' : { 'markdown' : 1, 'gitcommit' : 1 },
\ }

function! s:source.get_complete_position(context)
    echom a:context.input
    let colon_idx = strridx(a:context.input[:col('.')-1], ':')
    if colon_idx == -1
        return -1
    endif
    echom string(colon_idx)
    return colon_idx
endfunction

function! s:candidate_generator()
    if emoji#available()
        return '{
            \ "word" : ":" . v:val . ":",
            \ "abbr" : ":" . v:val . ": " . emoji#for(v:val),
            \ "menu" : "[github]",
            \ }'
    else
        return '{"word" : ":" . v:val . ":", "menu" : "[github]"}'
    endif
endfunction

function! s:source.gather_candidates(context)
    return map(emoji#list(), s:candidate_generator())
endfunction

function! neocomplete#sources#github_emoji#define()
    return s:has_vim_emoji() ? s:source : {}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
