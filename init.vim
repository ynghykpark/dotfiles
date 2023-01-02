" ----------------------------------------------------------------------
" | Helper Functions                                                   |
" ----------------------------------------------------------------------

function TabLine()
    let s = ''
    for i in range(tabpagenr('$'))
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif
	    let s .= ' %{TabLabel(' . (i + 1) . ')} '
    endfor
    let s .= '%#TabLineFill#%T'
    return s
endfunction

function TabLabel(n)
    let buf = tabpagebuflist(a:n)[tabpagewinnr(a:n) - 1]
    let s = ''
    if getbufinfo(buf)[0].changed
        let s .= '✚'
    endif
    let s .= fnamemodify(bufname(buf), ":t")
    return s
endfunction

function! InsertLine()
    let trace = expand("import pdb; pdb.set_trace()")
    execute "normal o".trace
endfunction

function! ColorScheme()

	if filereadable(expand("~/.local/share/nvim/plugged/seoul256.vim/colors/seoul256.vim"))
		colorscheme seoul256
		highlight Normal         cterm=none    ctermbg=none    ctermfg=253
		highlight Pmenu          cterm=none    ctermbg=237     ctermfg=253
		highlight PmenuSel       cterm=none    ctermbg=gray    ctermfg=253
		highlight PmenuSbar      cterm=none    ctermbg=gray    ctermfg=gray
		highlight PmenuThumb     cterm=none    ctermbg=gray    ctermfg=gray
		highlight MatchParen     cterm=none    ctermbg=green   ctermfg=black
		highlight LineNr         cterm=none    ctermbg=none    ctermfg=black
		highlight CursorLine     cterm=none    ctermbg=none
		highlight CursorLineNr   cterm=none    ctermbg=none
		highlight VertSplit      cterm=none    ctermbg=237      ctermfg=237
		highlight StatusLine     cterm=none    ctermbg=none     ctermfg=none
		highlight StatusLineNC   cterm=none    ctermbg=none     ctermfg=none
		highlight TabLineFill    cterm=none    ctermbg=237      ctermfg=none
		highlight TabLine        cterm=none    ctermbg=237      ctermfg=black
		highlight TabLineSel     cterm=none    ctermbg=237      ctermfg=253
	endif

endfunction

" ----------------------------------------------------------------------
" | General Settings                                                   |
" ----------------------------------------------------------------------

set nocompatible                    " Don't make Vim vi-compatibile.

syntax on                           " Enable syntax highlighting.

filetype plugin indent on
"           │     │    └──────── Enable file type detection.
"           │     └───────────── Enable loading of indent file.
"           └─────────────────── Enable loading of plugin files.

set autoindent                      " Copy indent to the new line.

set backspace=indent,eol,start      " make backspace behave in a sane manner

set clipboard=unnamed               " ┐
                                    " │ Use the system clipboard
if has('unnamedplus')               " │ as the default register.
    set clipboard+=unnamedplus      " │
endif                               " ┘

set encoding=utf-8 nobomb           " Use UTF-8 without BOM.

set laststatus=0                    " do not show the status line all the time

set statusline=%f

set lazyredraw                      " don't redraw while executing macros

set mousehide                       " Hide mouse pointer while typing.

set magic                           " Enable extended regexp.

set listchars=tab:▸\                " ┐
set listchars+=trail:·              " │ Use custom symbols to
set listchars+=eol:↴                " │ represent invisible characters.
set listchars+=nbsp:_               " ┘

set number                          " Show line number.
set relativenumber                  " show line number with relative number

set numberwidth=2

set showbreak=↪

set tabstop=4                       " ┐
set softtabstop=4                   " │ Set global <TAB> settings.
set shiftwidth=4                    " │
set expandtab                       " ┘

set cmdheight=1                     " command bar height

set undodir=~/.vim/undos        " Set directory for undo files.
set undofile                    " Automatically save undo history.

set visualbell                      " ┐
set noerrorbells                    " │ Disable beeping and window flashing.
set t_vb=                           " ┘ https://vim.wikia.com/wiki/Disable_beeping

set wildmenu                    " Enable enhanced command-line

set wildmode=list:longest,full

set hidden                      "current buffer can be put into background

set shell=$SHELL                "set shell for vim as default bash

set splitbelow

set splitright

set noswapfile

set noshowcmd

"Disable automatic comment
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o

" ----------------------------------------------------------------------
" | Key Mappings                                                       |
" ----------------------------------------------------------------------

" Use a different mapleader (default is "\").
let mapleader = " "

" Sudo write.
map <leader>W :w !sudo tee %<CR>

nnoremap <silent> <leader><space> :silent w<cr>
nnoremap <silent> <leader>b :ls<cr>:b<space>
nnoremap <silent> <leader>hs :setlocal hlsearch!<cr>
nnoremap <silent> <leader>l :set list!<cr>
nnoremap <silent> <leader>n :set number! norelativenumber!<cr>
nnoremap j gj
nnoremap k gk
nnoremap <Leader>bb <Cmd>lua require('comment-box').acbox()<CR>
vnoremap <Leader>bb <Cmd>lua require('comment-box').acbox()<CR>
inoremap <C-u> <esc>vbUea

" ----------------------------------------------------------------------
" | Plugins                                                            |
" ----------------------------------------------------------------------

call plug#begin('~/.local/share/nvim/plugged')
    Plug 'benmills/vimux' "vimux makes vim control tmux pane
    Plug 'christoomey/vim-tmux-navigator' "Navigate tmux and vim seamlessly
    Plug 'ddollar/nerdcommenter' "you don't need to memorize which char is a comment
    Plug 'duff/vim-trailing-whitespace' "Erase trailing whitespace automatically.
    Plug 'machakann/vim-highlightedyank' "highlight yank.
    Plug 'sheerun/vim-polyglot' "For better syntax highlight!
    Plug 'simeji/winresizer' "Easy resizing of vim panes
    Plug 'junegunn/seoul256.vim'
    Plug 'LudoPinelli/comment-box.nvim'
    " Languagre Server Protocol and Auto completion
    Plug 'prabirshrestha/vim-lsp'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
call plug#end()

" Vimux
let g:VimuxHeight="20"
let g:VimuxOrientation="v"
let g:VimuxUseNearest = 1
let g:VimuxResetSequence = "q C-u"
let g:VimuxPromptString = "Command? "
let g:VimuxRunnerType = "pane"
map <Leader>vp :VimuxPromptCommand<CR>

" Colorscheme
call ColorScheme()

" Whitespace
nnoremap <silent> <leader>f :FixWhitespace<cr>

" LSP
" let g:lsp_preview_keep_focus=0
" let g:asyncomplete_auto_popup=0
let g:lsp_diagnostics_enabled = 0         " disable diagnostics support
let g:lsp_highlight_references_enabled = 0

" ----------------------------------------------------------------------
" | Python Specific                                                    |
" --------------------------------------------------------------------

" python specific option
augroup filetype_python
autocmd!
autocmd FileType python nnoremap <buffer> <leader>mk
            \ :call VimuxRunCommand("clear;python3 " . expand("%"))<cr>
autocmd FileType python nnoremap <buffer> <leader>mi
            \ :call VimuxRunCommand("clear;python3 -i " . expand("%"))<cr>
autocmd FileType python nnoremap <buffer> <leader>mc
            \ :call VimuxRunCommand("clear;python3 -m pdb -c continue " . expand("%"))<cr>
autocmd FileType python nnoremap <buffer> <leader>p :call InsertLine()<cr>

set completeopt=noinsert,menuone,noselect

augroup END

if executable('pyls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pyls',
        \ 'cmd': {server_info->['pyls']},
        \ 'whitelist': ['python'],
        \ })
endif

if executable('texlab')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'texlab',
        \ 'cmd': {server_info->['texlab']},
        \ 'whitelist': ['tex', 'bib', 'sty'],
        \ })
endif

if executable('clangd-9')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'clangd',
        \ 'cmd': {server_info->['clangd-9']},
        \ 'whitelist': ['cpp', 'h', 'hpp'],
        \ })
endif
