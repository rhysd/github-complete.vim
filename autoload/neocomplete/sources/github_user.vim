let s:save_cpo = &cpo
set cpo&vim

" Note:
" github_issue controls its cache by itself
let s:source = {
\ 'name'        : 'github_user',
\ 'rank'        : 200,
\ 'kind'        : 'manual',
\ 'is_volatile' : 1,
\ 'disabled'    : !g:github_complete#enable_neocomplete,
\ }

function! s:source.get_complete_position(context)
    return match(a:context.input[:col('.')-1], '\%(@\|\<github\.com/\zs\)\w\+$')
endfunction

function! s:source.gather_candidates(context)
    let input = a:context.input[:col('.')-1]
    let idx = strridx(input, '@')
    let base = input[idx:]
    return github_complete#user#candidates_async(base)
endfunction

function! neocomplete#sources#github_user#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
