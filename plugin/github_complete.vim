if (exists('g:loaded_github_complete') && g:loaded_github_complete) || &cp
    finish
endif
let g:loaded_github_complete = 1

if !empty(g:github_complete#fetch_issues_filetypes)
    augroup plugin-github-complete-fetch-issues
        autocmd!
        for s:ft in g:github_complete#fetch_issues_filetypes
            execute 'autocmd FileType' s:ft 'call github_complete#issue#fetch_issues()'
        endfor
        unlet! s:ft
    augroup END
endif
