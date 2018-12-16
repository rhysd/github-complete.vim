let s:save_cpo = &cpo
set cpo&vim

let s:vital = github_complete#import_vital()
let s:H = s:vital['Web.HTTP']
let s:J = s:vital['Web.JSON']
let s:O = s:vital['Data.Optional']
let s:P = s:vital['Process']

let s:cache = {}

function! s:api_error(res)
    call github_complete#error('API request was failed with status ' . a:res.status . ': ' . a:res.statusText)
endfunction

function! s:cache_key_of(path, param)
    if type(a:param) == type({})
        return a:path . string(a:param)
    else
        return a:path . a:param
    endif
endfunction

function! github_complete#api#call_sync(path, params)
    let headers = {'Accept' : 'application/vnd.github.v3+json'}
    if g:github_complete_github_api_token !=# ''
        let headers.Authorization = 'token ' . g:github_complete_github_api_token
    endif
    if g:github_complete_ghe_host !=# ''
      let url = 'https://' . g:github_complete_ghe_host . '/api/v3/'
    else
      let url = 'https://api.github.com/'
    endif
    let url = url . a:path
    let response = s:H.request({
        \ 'url' : url,
        \ 'headers' : headers,
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

function! github_complete#api#call_sync_cached(path, params)
    let key = s:cache_key_of(a:path, a:params)

    if has_key(s:cache, key)
        return s:cache[key]
    endif

    if has_key(s:working_processes, key)
        let result = s:response_of(s:working_processes[key], key, a:path)
        if !s:O.empty(result)
            return s:O.get(result)
        endif
    endif

    let response = github_complete#api#call_sync(a:path, a:params)
    let s:cache[key] = response
    return response
endfunction

let s:working_processes = {}

function! github_complete#api#fetch_call_async(path, params, consider_cache)
    if !s:P.has_vimproc()
        return
    endif

    let key = s:cache_key_of(a:path, a:params)

    if has_key(s:working_processes, key)
        " The API call was already fetched
        return
    endif

    if a:consider_cache && has_key(s:cache, key)
        return
    endif

    let headers = {'Accept' : 'application/vnd.github.v3+json'}
    if g:github_complete_github_api_token !=# ''
        let headers.Authorization = 'token ' . g:github_complete_github_api_token
    endif
    let request = s:H.request_async({
        \ 'url' : 'https://api.github.com/' . a:path,
        \ 'headers' : headers,
        \ 'method' : 'GET',
        \ 'param' : a:params,
        \ 'client' : ['curl', 'wget'],
        \ })
    let s:working_processes[key] = request
endfunction

function! s:response_of(request, key, path)
    let [condition, status] = a:request.process.checkpid()
    if condition ==# 'exit'
        call a:request.process.stdout.close()
        call a:request.process.stderr.close()

        unlet! s:working_processes[a:key]

        let response = a:request.callback(a:request.files)
        if !response.success
            call s:api_error(response)
            return s:O.none()
        endif

        return s:O.some(s:J.decode(response.content))
    elseif condition ==# 'error'

        call a:request.process.stdout.close()
        call a:request.process.stderr.close()
        unlet! s:working_processes[a:key]

        call github_complete#error('Failed to call API https://api.github.com/' . a:path)
        return s:O.none()
    else
        " Note: process has not been done yet.
        return s:O.none()
    endif
endfunction

function! github_complete#api#call_async(path, params)
    let key = s:cache_key_of(a:path, a:params)

    if has_key(s:working_processes, key)
        return s:response_of(s:working_processes[key], key, a:path)
    endif

    call github_complete#api#fetch_call_async(a:path, a:params, 0)
    return s:O.none()
endfunction

function! github_complete#api#call_async_cached(path, params)
    let key = s:cache_key_of(a:path, a:params)

    if has_key(s:cache, key)
        return s:cache[key]
    endif

    if !has_key(s:working_processes, key)
        call github_complete#api#fetch_call_async(a:path, a:params, 1)
        return []
    endif

    let call_result = s:response_of(s:working_processes[key], key, a:path)

    if s:O.empty(call_result)
        return []
    endif

    let response = s:O.get(call_result)
    let s:cache[key] = response
    return response
endfunction

function! github_complete#api#reset_cache(...)
    if a:0 == 0
        let s:cache = {}
        return
    endif

    if a:0 == 1
        unlet! s:cache[a:1]
    endif

    if a:0 == 2
        unlet! s:cache[s:cache_key_of(a:1, a:2)]
    endif
endfunction

function! github_complete#api#is_cached(path, params)
    return has_key(s:cache, s:cache_key_of(a:path, a:params))
endfunction

function! github_complete#api#get_cache(...)
    if a:0 == 0
        return deepcopy(s:cache)
    endif

    if a:0 == 1
        return deepcopy(get(s:cache, a:1, {}))
    endif

    if a:0 == 2
        return deepcopy(get(s:cache, s:cache_key_of(a:1, a:2), {}))
    endif

    return {}
endfunction

function! github_complete#api#debug_working_process()
    return s:working_processes
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

