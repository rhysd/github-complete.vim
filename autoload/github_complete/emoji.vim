let s:save_cpo = &cpo
set cpo&vim

function! github_complete#emoji#find_start(input)
    return github_complete#find_start(a:input, ':\w*$', 'emoji')
endfunction

function! s:abbr_workaround(emoji)
    if !g:github_complete_emoji_japanese_workaround
        return ''
    endif

    let desc = github_complete#emoji#japanese#for(a:emoji)
    if desc ==# ''
        return ''
    endif

    return " -> " . desc
endfunction

if github_complete#emoji#data#available()
    let s:candidates = map(github_complete#emoji#data#list(), '{
                \ "word" : ":" . v:val . ":",
                \ "abbr" : ":" . v:val . ": " . github_complete#emoji#data#for(v:val),
                \ "menu" : "[emoji]",
                \ }')
else
    " Note:
    " Add more workaround for the environment emojis are unavailable
    let s:candidates = map(github_complete#emoji#data#list(), '{
                \ "word" : ":" . v:val . ":",
                \ "abbr" : ":" . v:val . ":" . s:abbr_workaround(v:val),
                \ "menu" : "[emoji]",
                \ }')
endif

function! github_complete#emoji#candidates(base)
    if !g:github_complete_enable_emoji_completion
        return []
    endif

    if a:base ==# ''
        return s:candidates
    else
        let len = strlen(a:base)
        return filter(copy(s:candidates), 'stridx(v:val.word, a:base) == 0')
    endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

