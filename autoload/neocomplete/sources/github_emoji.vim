let s:save_cpo = &cpo
set cpo&vim

let s:source = {
\ 'name'     : 'github_emoji',
\ 'rank'     : 200,
\ 'kind'     : 'manual',
\ 'disabled' : !g:github_complete_enable_neocomplete,
\ 'filetypes' : {'gitcommit' : 1, 'markdown' : 1, 'magit' : 1},
\ }

function! s:source.get_complete_position(context)
    return github_complete#emoji#find_start(a:context.input)
endfunction

function! s:source.gather_candidates(context)
    return github_complete#emoji#candidates('')
endfunction

function! neocomplete#sources#github_emoji#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
