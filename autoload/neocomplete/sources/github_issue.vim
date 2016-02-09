let s:save_cpo = &cpo
set cpo&vim

" Note:
" github_issue controls its cache by itself
let s:source = {
\ 'name'        : 'github_issue',
\ 'rank'        : 200,
\ 'kind'        : 'manual',
\ 'is_volatile' : 1,
\ 'disabled'    : !g:github_complete_enable_neocomplete,
\ 'filetypes' : {'gitcommit' : 1, 'markdown' : 1, 'magit' : 1},
\ }

function! s:source.get_complete_position(context)
    return strridx(a:context.input[ : col('.')-1], '#')
endfunction

function! s:source.gather_candidates(context)
    return github_complete#issue#candidates_async('')
endfunction

function! neocomplete#sources#github_issue#define()
    return s:source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
