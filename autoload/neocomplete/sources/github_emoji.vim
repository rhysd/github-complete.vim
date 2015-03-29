let s:save_cpo = &cpo
set cpo&vim

let s:source = {
\ 'name'     : 'github_emoji',
\ 'rank'     : 200,
\ 'kind'     : 'manual',
\ 'disabled' : 1,
\ }

function! s:source.get_complete_position(context)
    return strridx(a:context.input[:col('.')-1], ':')
endfunction

function! s:source.gather_candidates(context)
    return github_complete#emoji#candidates('')
endfunction

function! neocomplete#sources#github_emoji#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
