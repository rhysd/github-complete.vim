let s:save_cpo = &cpo
set cpo&vim

function! github_complete#emoji#has_vim_emoji()
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

function! github_complete#emoji#find_start(input)
    if !g:github_complete#enable_emoji_completion
        return -1
    endif
    return match(a:input[:col('.') - 1], ':\w*$')
endfunction

function! github_complete#emoji#is_available(base)
    return a:base =~# '^:\w*$'
endfunction

if github_complete#emoji#has_vim_emoji()
    if emoji#available()
        let s:candidates = map(emoji#list(), '{
                    \ "word" : ":" . v:val . ":",
                    \ "abbr" : ":" . v:val . ": " . emoji#for(v:val),
                    \ "menu" : "[emoji]",
                    \ }')
    else
        " Note:
        " Add more workaround for the environment emojis are unavailable
        let s:candidates = map(emoji#list(), '{
                    \ "word" : ":" . v:val . ":",
                    \ "menu" : "[emoji]",
                    \ }')
    endif
    function! github_complete#emoji#candidates(base)
        if !g:github_complete#enable_emoji_completion
            return []
        endif

        if a:base ==# ''
            return s:candidates
        else
            let len = strlen(a:base)
            return filter(copy(s:candidates), 'stridx(v:val.word, a:base) == 0')
        endif
    endfunction
else
    function! github_complete#emoji#candidates(...)
        return []
    endfunction
endif

let &cpo = s:save_cpo
unlet s:save_cpo

