let s:save_cpo = &cpo
set cpo&vim

let [s:P, s:H, s:J] = github_complete#import_vital()

function! github_complete#api#call(path, params)
    let response = s:H.request({
        \ 'url' : 'https://api.github.com/' . a:path,
        \ 'headers' : {'Accept' : 'application/vnd.github.v3+json'},
        \ 'method' : 'GET',
        \ 'param' : a:params,
        \ 'client' : ['curl', 'wget'],
        \ })
    if !response.success
        call github_complete#error('API request was failed with status' . response.status . ': ' . response.statusText)
        return []
    endif
    return s:J.decode(response.content)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

