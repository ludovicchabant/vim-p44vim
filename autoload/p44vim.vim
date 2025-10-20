
" Utilities {{{

function! s:trace(msg) abort
    if g:p44v_trace
        echom "p44vim: ".a:msg
    endif
endfunction

function! s:throw(msg) abort
    throw "p44vim: ".a:msg
endfunction

function! s:run_perforce_command(...) abort
    let l:args = a:000
    if a:0 == 1 && type(a:1) == type([])
        let l:args = a:1
    endif
    let l:cmd = ['p4']
    call extend(l:cmd, l:args)
    let l:strcmd = join(map(l:cmd, 'shellescape(v:val)'))
    call s:trace("Running command: ".l:strcmd)
    let l:cmd_out = system(l:strcmd)
    if g:p44v_trace
        call s:trace(l:cmd_out)
    endif
    return l:cmd_out
endfunction

function! s:get_p4_depot_root(path) abort
    let l:cur = a:path
    let l:prev_cur = ''
    while l:cur != l:prev_cur
        if filereadable(l:cur.'/.p4config') ||
                    \filereadable(l:cur.'/.p4ignore') ||
                    \filereadable(l:cur.'/.p4ignore.txt')
            return l:cur
        endif
        let l:prev_cur = l:cur
        let l:cur = fnamemodify(l:cur, ':h')
    endwhile
    call s:throw("No p4 depot found at: ".a:path)
endfunction

" }}}

" Auto-commands {{{

let s:ignore_next_w12 = 0

function! s:maybe_auto_edit_buffer() abort
    if &readonly && !g:p44v_disable
        if !g:p44v_just_make_rw
            call p44vim#p4edit()
        else
            call p44vim#makerw()
        endif
    endif
endfunction

function! s:maybe_ignore_w12() abort
    if s:ignore_next_w12
        let v:fcs_choice = ''  " Ignore the warning, keep the file.
        let s:ignore_next_w12 = 0
    endif
endfunction

function! p44vim#install_p4_auto_commands() abort
    call s:trace("Scanning buffer '".bufname('%')."' for Perforce setup...")
    try
        let l:repo_root = s:get_p4_depot_root(expand('%:h'))
    catch /^p44vim\:/
        return
    endtry

    let b:p44v_repo_root = l:repo_root
    call s:trace("Setting up P4 auto-commands for: ".bufname('%'))

    augroup p44v_auto
        autocmd!
        autocmd BufWritePre * call <SID>maybe_auto_edit_buffer()
        autocmd FileChangedShell * call <SID>maybe_ignore_w12()
    augroup END
endfunction

" }}}

" Commands {{{

function! p44vim#p4info() abort
    echom s:run_perforce_command(['info'])
endfunction

function! p44vim#p4sync(...) abort
    let l:cmd = ['sync'] + a:000
    call s:run_perforce_command(l:cmd)
endfunction

function! p44vim#p4edit(...) abort
    if a:0
        let l:filenames = a:000
    else
        let l:filenames = [expand('%:p')]
    endif
    let l:cmd = ['edit'] + l:filenames
    let l:ignore_next_w12 = 1
    call s:run_perforce_command(l:cmd)
    set noreadonly
endfunction

function! p44vim#makerw(...) abort
    if a:0
        let l:filenames = a:000
    else
        let l:filenames = [expand('%:p')]
    endif
    call s:trace("Making ".len(l:filenames)." files writable")
    for fname in l:filenames
        call setfperm(fname, "rw-r-----")
    endfor
endfunction

function! p44vim#p4revert(...) abort
    if a:0
        let l:filenames = a:000
    else
        let l:filenames = [expand('%:p')]
    endif
    let l:cmd = ['revert'] + l:filenames
    call s:run_perforce_command(l:cmd)
    silent edit
endfunction

" }}}

