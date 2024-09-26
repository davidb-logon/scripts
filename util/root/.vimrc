fu! SaveSess()
execute 'mksession! ' . getcwd() . '/.' . expand('%:t') . '.vim'
endfunction
 
fu! RestoreSess()
 if filereadable(getcwd() . '/.' . expand('%:t') . '.vim')
 execute 'so ' . getcwd() . '/.' . expand('%:t') . '.vim'
 if bufexists(1)
 for l in range(1, bufnr('$'))
 if bufwinnr(l) == -1
 exec 'sbuffer ' . l
 endif
 endfor
 endif
 endif
endfunction
 
autocmd VimLeavePre * call SaveSess()
autocmd VimEnter * nested call RestoreSess()
colorscheme blue
set nu
set noswapfile
set nobackup
set nowritebackup
set noundofile
