let s:save_cpo = &cpo
set cpo&vim

" Note:
" github_issue controls its cache by itself
let s:source = {
\ 'name'        : 'github_repo',
\ 'rank'        : 200,
\ 'kind'        : 'manual',
\ 'is_volatile' : 1,
\ 'disabled'    : !g:github_complete_enable_neocomplete,
\ 'filetypes' : {'gitcommit' : 1, 'markdown' : 1, 'magit' : 1},
\ }

function! s:source.get_complete_position(context)
    return match(a:context.input[ : col('.')-1], '[[:alnum:]-_]\+/[[:alnum:]-_]\+$')
endfunction

function! s:source.gather_candidates(context)
    let repo_name = matchstr(a:context.complete_str, '/\zs[[:alnum:]-_]\+$')
    if strlen(repo_name) < g:neocomplete#min_keyword_length
        return []
    endif
    return github_complete#repo#candidates_async(a:context.complete_str)
endfunction

function! neocomplete#sources#github_repo#define()
    return s:source
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
