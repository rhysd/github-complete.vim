if (exists('g:loaded_github_complete') && g:loaded_github_complete) || &cp
    finish
endif
let g:loaded_github_complete = 1

" Variables {{{
function! s:set_global_var(name, default)
    let g:github_complete_{a:name} = get(g:, 'github_complete_' . a:name, a:default)
endfunction

call s:set_global_var('overwrite_omnifunc_filetypes', [])
call s:set_global_var('enable_neocomplete', 0)
call s:set_global_var('enable_emoji_completion', 1)
call s:set_global_var('enable_issue_completion', 1)
call s:set_global_var('enable_user_completion', 1)
call s:set_global_var('enable_repo_completion', 1)
call s:set_global_var('enable_link_completion', 1)
call s:set_global_var('include_issue_title', 0)
call s:set_global_var('max_issue_candidates', 100)
call s:set_global_var('issue_request_params', {'state' : 'all'})
call s:set_global_var('git_cmd', 'git')
call s:set_global_var('fetch_issue_api_filetypes', ['gitcommit'])
call s:set_global_var('emoji_japanese_workaround', 0)
call s:set_global_var('fallback_omnifunc', '')
call s:set_global_var('enable_api_cache', 1)
call s:set_global_var('enable_omni_completion', 1)
call s:set_global_var('github_api_token', $GITHUB_API_TOKEN)
call s:set_global_var('ghe_host', '')
" }}}


if !empty(g:github_complete_fetch_issue_api_filetypes) && g:github_complete_enable_api_cache
    augroup plugin-github-complete-fetch-issues
        autocmd!
        for s:ft in g:github_complete_fetch_issue_api_filetypes
            execute 'autocmd FileType' s:ft 'silent! call github_complete#issue#fetch_issues()'
        endfor
        unlet! s:ft
    augroup END
endif

if !empty(g:github_complete_overwrite_omnifunc_filetypes)
    augroup plugin-github-complete-overwrite-omnifunc
        autocmd!
        execute 'autocmd FileType' join(g:github_complete_overwrite_omnifunc_filetypes, ',') 'set omnifunc=github_complete#complete'
    augroup END
endif

inoremap <silent><Plug>(github-complete-manual-completion) <C-r>=github_complete#manual_complete()<CR>

