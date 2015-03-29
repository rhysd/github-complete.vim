let s:save_cpo = &cpo
set cpo&vim

let s:vital = github_complete#import_vital()
let s:H = s:vital['Web.HTTP']
let s:J = s:vital['Web.JSON']
let s:O = s:vital['Data.Optional']

function! s:api_error(error_response)
    call github_complete#error('API request was failed with status ' . response.status . ': ' . response.statusText)
endfunction

function! github_complete#api#call(path, params)
    let response = s:H.request({
        \ 'url' : 'https://api.github.com/' . a:path,
        \ 'headers' : {'Accept' : 'application/vnd.github.v3+json'},
        \ 'method' : 'GET',
        \ 'param' : a:params,
        \ 'client' : ['curl', 'wget'],
        \ })
    if !response.success
        call s:api_error(response)
        return []
    endif
    return s:J.decode(response.content)
endfunction

let s:working_processes = {}

function! github_complete#api#fetch_call_async(path, params)
    if has_key(s:working_processes, a:path)
        " The API call was already fetched
        return
    endif

    let request = s:H.request_async({
        \ 'url' : 'https://api.github.com/' . a:path,
        \ 'headers' : {'Accept' : 'application/vnd.github.v3+json'},
        \ 'method' : 'GET',
        \ 'param' : a:params,
        \ 'client' : ['curl', 'wget'],
        \ })
    let s:working_processes[a:path] = request
endfunction

function! s:response_of(request, path)
    let [condition, status] = a:request.process.checkpid()
    PP! [condition, status]
    if condition ==# 'exit'
        call a:request.process.stdout.close()
        call a:request.process.stderr.close()

        unlet! s:working_processes[a:path]

        let response = a:request.callback(a:request.files)
        if !response.success
            call s:api_error(response)
            return s:O.none()
        endif

        return s:O.some(s:J.decode(response.content))
    elseif condition ==# 'error'
        call a:request.process.stdout.close()
        call a:request.process.stderr.close()
        unlet! s:working_processes[a:path]

        call github_complete#error('Failed to call API https://api.github.com/' . a:path)
        return s:O.none()
    else
        " Note: process has not been done yet.
        return s:O.none()
    endif
endfunction

function! github_complete#api#call_async(path, params)
    if has_key(s:working_processes, a:path)
        echom "already fetched: " . a:path
        return s:response_of(s:working_processes[a:path], a:path)
    endif

    call github_complete#api#fetch_call_async(a:path, a:params)
    return s:O.none()
endfunction

let s:cache = {}

function! github_complete#api#call_cached(path, params)
    let response = github_complete#api#call(a:path, a:params)
    let s:cache[a:path] = response
    return response
endfunction

function! github_complete#api#call_async_cached(path, params)
    if has_key(s:cache, a:path)
        return s:cache[a:path]
    endif

    let call_result = github_complete#api#call_async(a:path, a:params)

    if s:O.empty(call_result)
        return []
    endif

    let response = s:O.get(call_result)
    let s:cache[a:path] = response
    return response
endfunction

function! github_complete#api#reset_cache(...)
    if a:0 == 0
        let s:cache = {}
        return
    endif

    unlet! s:cache[a:1]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

