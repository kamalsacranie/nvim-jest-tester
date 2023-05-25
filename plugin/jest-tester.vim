" Prevent loading plugin twice
if exists('g:jest_tester_loaded') | finish | endif

if !has('nvim')
  echohl Error
  echom "Sorry this plugin only works with neovim version that support lua"
  echohl clear
  finish
endif

lua require'jest-tester'.setup()
let g:jest_tester_loaded = 1

" Create vim command
command! JestTest :lua require'jest-tester'.test()
