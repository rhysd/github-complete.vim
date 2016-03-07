if g:github_complete_enable_omni_completion && (&ofu ==# '' || &ofu ==# 'htmlcomplete#CompleteTags')
    setlocal omnifunc=github_complete#complete
endif
