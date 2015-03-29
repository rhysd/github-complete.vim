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

function! github_complete#emoji#find_start()
    let c = col('.') - 1
    let input = getline('.')[:c]
    let idx = strridx(input, ':')
    if idx == -1
        return c
    else
        return idx
    endif
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
        if a:base ==# ''
            return s:candidates
        else
            return filter(copy(s:candidates), 'stridx(v:val.word, a:base) == 0')
        endif
    endfunction
else
    function! github_complete#emoji#candidates()
        return []
    endfunction
endif
