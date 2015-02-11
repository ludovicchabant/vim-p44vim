
if exists('g:loaded_p44v') && !exists('g:p44v_debug')
    finish
endif
let g:loaded_p44v = 1

if !exists('g:p44v_trace')
    let g:p44v_trace = 0
endif

if !exists('g:p44v_exe')
    let g:p44v_exe = 'p4'
endif

if !executable(g:p44v_exe)
    echoerr "p44vim: '".g:p44v_exe."' is not a known executable. ".
                \"Perforce commands won't work."
endif

" Autocommands {{{

" When a new buffer is opened, try to figure out if it's in a P4 depot.
" If it is, then setup some auto-commands to do stuff like auto-open-for-edit
" when you start editing the file.
augroup p44v_auto_detect
    autocmd!
    autocmd BufRead * call p44vim#install_p4_auto_commands()
augroup END

" }}}

" P4 Commands {{{

command! -nargs=* -complete=file P4Sync :call p44vim#p4sync(<f-args>)
command! -nargs=* -complete=file P4Edit :call p44vim#p4edit(<f-args>)
command! -nargs=* -complete=file P4Revert :call p44vim#p4revert(<f-args>)

" }}}

