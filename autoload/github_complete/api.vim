let s:save_cpo = &cpo
set cpo&vim

let s:vital = github_complete#import_vital()
let s:H = s:vital['Web.HTTP']
let s:J = s:vital['Web.JSON']
let s:O = s:vital['Data.Optional']

let s:cache = {}

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

function! github_complete#api#fetch_call_async(path, params, consider_cache)
    if has_key(s:working_processes, a:path)
        " The API call was already fetched
        return
    endif

    if a:consider_cache && has_key(s:cache, a:path)
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
        return s:response_of(s:working_processes[a:path], a:path)
    endif

    call github_complete#api#fetch_call_async(a:path, a:params, 0)
    return s:O.none()
endfunction

function! github_complete#api#call_cached(path, params)
    if has_key(s:cache, a:path)
        return s:cache[a:path]
    endif

    if has_key(s:working_processes, a:path)
        let result = s:response_of(s:working_processes[a:path], a:path)
        if !s:O.empty(result)
            return s:O.get(result)
        endif
    endif

    let response = github_complete#api#call(a:path, a:params)
    let s:cache[a:path] = response
    return response
endfunction

function! github_complete#api#call_async_cached(path, params)
    if has_key(s:cache, a:path)
        return s:cache[a:path]
    endif

    if !has_key(s:working_processes, a:path)
        call github_complete#api#fetch_call_async(a:path, a:params, 1)
        return []
    endif

    let call_result = s:response_of(s:working_processes[a:path], a:path)

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

function! github_complete#api#is_cached(path)
    return has_key(s:cache, a:path)
endfunction

function! github_complete#api#get_cache(...)
    if a:0 == 0
        return deepcopy(s:cache)
    endif

    if has_key(s:cache, a:1)
        return deepcopy(s:cache[a:1])
    else
        return {}
    endif
endfunction

function! github_complete#api#debug_working_process()
    let wp = s:working_processes
    PP! wp
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

