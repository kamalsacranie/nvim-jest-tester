" Prevent loading plugin twice
if exists('g:jest_tester_loaded') | finish | endif

" let s:save_cpo = &cpo
" set cpo&vim

if !has('nvim')
  echohl Error
  echom "Sorry this plugin only works with neovim version that support lua"
  echohl clear
  finish
endif

lua require'jest-tester'.setup()
let g:jest_tester_loaded = 1

" Create vim command
command! JestTest :lua require'clipboard-image.paste'.paste_img()

" let &cpo = s:save_cpo
" unlet s:save_cpo
