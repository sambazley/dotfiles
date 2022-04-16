"line numbers
set number relativenumber
"indent 4 spaces, <BS> deletes 4 spaces
set shiftwidth=8 smarttab
"red line after 80th char
set colorcolumn=80
"syntax highlighting
syntax enable
"set font
set guifont=Source\ Code\ Pro\ 9
"enable mouse input (scrolling)
set mouse=a
"disable replace on <Insert>
imap <Insert> <Nop>
"enabled search highlighting
set hlsearch
"disable line wrapping
set nowrap
"show search terms while typing
set incsearch
"disable bells
set visualbell
set noerrorbells
set showcmd
"file type detection
filetype plugin indent on
"change buffer without saving
set hidden
"always show lines above/below cursor
set scrolloff=4
"enable cmdline menu
set wildmenu
"enable spellcheck
set spell
set spelllang=en_gb
"set terminal title
set title

set cursorline
set cursorlineopt=number

set background=dark

set fileencodings=utf-8,default,latin1
set fileencoding=utf-8

function! StatusBuffers()
    let statusline = ""

    let width = winwidth(0) - 3

    let buffers = []
    let ndx = 0

    for b in split(execute("ls"), "\n")
        let buf = {}

        let buf.modified = split(b)[2] == "+"
        let buf.name = split(b, "\"")[1]
        let buf.line = split(b)[-1]
        let buf.done = 0

        if split(b)[1][0] == "%"
            let width -= len(buf.name) + len(buf.line)*2 + (buf.modified ? 3 : 2)
            let ndx = 1
            continue
        endif

        if ndx
            call insert(buffers, buf, ndx - 1)
            let ndx += 1
        else
            call add(buffers, buf)
        endif
    endfor

    for b in buffers
        let width -= len(b.name . b.line) + (b.modified ? 3 : 2)

        if width <= 3
            let w = 0
            for b in buffers
                if !b.done && b.modified
                    let statusline .= "%#SLModified#***%#StatusLineNC#"
                    let w = 1
                    break
                endif
            endfor

            if !w
                let statusline .= "..."
            endif

            break
        endif

        let b.done = 1

        let statusline .= b.name . ":" . b.line . (b.modified ? "%#SLModified#*%#StatusLineNC#" : "") . " "
    endfor

    return statusline
endfunction

"statusline
"always on
set laststatus=2
"filename
set statusline=%f
"line number
set statusline+=:%l
"todo highlighting
set statusline+=%#SLModified#
"if modified, display *
set statusline+=%{&modified?\"*\":\"\"}
"reset to default highlighting
set statusline+=%#slnorm#
"keep alignment if not modified
set statusline+=%{&modified?\"\":\"\ \"}
"error highlighting
set statusline+=%#SLReadOnly#
"show readonly flag
set statusline+=%{&readonly?\"[READ\ ONLY]\":\"\"}
"reset to default highlighting
set statusline+=%#slnorm#
set statusline+=%{&readonly?\"\ \":\"\ \"}
"show buffers
set statusline+=%#StatusLineNC#%{%StatusBuffers()%}
"align right
set statusline+=%=
"line:column
set statusline+=%l\:%c

if &t_Co != 8
    source ~/.vim/theme.vim
else
    hi SLModified ctermfg=0 ctermbg=3
    hi SLReadOnly term=bold ctermbg=1
endif

function! s:insert_license()
    let done = 0
    for f in ["boilerplate", "LICENSE"]
        if done
            break
        endif

        for p in ["", "../"]
            let pf = p . f
            echom pf
            if filereadable(pf)
                exec '0read' pf
                norm G
                let done = 1
                break
            endif
        endfor
    endfor
endfunction
autocmd! BufNewFile *.{c,h} call <SID>insert_license()

function! s:insert_gates()
    let gatename = substitute(toupper(expand("%:t")), "\\.", "_", "g")
    execute "normal! i#ifndef " . gatename
    execute "normal! o#define " . gatename . "\n\n\n"
    execute "normal! Go#endif /* " . gatename . " */"
    normal! kk
endfunction
autocmd! BufNewFile *.h call <SID>insert_gates()

function! s:insert_vhdl()
    set filetype=vhdl "trigger vim-sleuth

    let entity = substitute(expand("%:t"), "-", "_", "g")[:-6]
    execute "normal! ilibrary ieee;\n"
    execute "normal! iuse ieee.std_logic_1164.all;\n"
    execute "normal! iuse ieee.numeric_std.all;\n\n"

    execute "normal! ientity " . entity . " is\n"
    execute "normal! i\<Tab>port (\n"
    execute "normal! i\<Tab>\<Tab>\n"
    execute "normal! i\<Tab>);\n"
    execute "normal! iend " . entity . ";\n\n"

    execute "normal! iarchitecture " . entity . "_arch of " . entity . " is\n"
    execute "normal! ibegin\n"
    execute "normal! i\<Tab>\n"
    execute "normal! iend " . entity . "_arch;"
    normal! 7k$
endfunction
augroup vhdl
    autocmd!
    autocmd BufNewFile *.vhdl call <SID>insert_vhdl()
augroup END

let g:vhdl_indent_genportmap = 0

set signcolumn=no

let g:lsp_peek_alignment = "top"
let g:lsp_preview_max_height = 20
let g:lsp_preview_autoclose = 0
let g:lsp_highlight_references_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_text_edit_enabled = 0
let g:asyncomplete_auto_popup = 0

if &term == 'xterm-color'
    let g:indentLine_char = '|'
    let g:lsp_auto_enable = 0
else
    let g:indentLine_setColors = 0
    let g:indentLine_char = '⎸'
    let g:indentLine_fileTypeExclude = ['json']
endif

function! s:check_back_space() abort
    let col = col('.') - 1
    return !col || (getline('.')[col - 1] =~ '\s' && getline('.')[col - 2] != ',')
endfunction

inoremap <silent><expr> <TAB>
            \ pumvisible() ? "\<C-n>" :
            \ <SID>check_back_space() ? "\<TAB>" :
            \ asyncomplete#force_refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
inoremap <expr><cr>    pumvisible() ? "\<C-y>" : "\<cr>"

if executable('clangd')
    au User lsp_setup call lsp#register_server({
                \ 'name': 'clangd',
                \ 'cmd': {server_info->['clangd', '-background-index']},
                \ 'allowlist': ['c', 'cpp', 'objc', 'objcpp'],
                \ })
endif
if executable('bash-language-server')
    au User lsp_setup call lsp#register_server({
                \ 'name': 'bash-language-server',
                \ 'cmd': {server_info->[&shell, &shellcmdflag, 'bash-language-server start']},
                \ 'allowlist': ['sh'],
                \ })
endif
if executable('vim-language-server')
    au User lsp_setup call lsp#register_server({
                \ 'name': 'vim-language-server',
                \ 'cmd': {server_info->[&shell, &shellcmdflag, 'vim-language-server --stdio']},
                \ 'allowlist': ['vim'],
                \ })
endif

nnoremap gd :LspDefinition<CR>

call plug#begin('~/.vim/plugged')
    Plug 'bronson/vim-trailing-whitespace'
    Plug 'prabirshrestha/async.vim'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
    Plug 'tpope/vim-fugitive'
    Plug 'tpope/vim-sleuth'
    Plug 'tpope/vim-speeddating'
    Plug 'yggdroot/indentline'
    Plug 'romainl/vim-cool'
    Plug 's3rvac/AutoFenc'
    Plug 'godlygeek/tabular'
    Plug 'junegunn/fzf.vim'
    Plug 'jceb/vim-orgmode'
    Plug 'sambazley/vim-csveval'
call plug#end()

nmap <LeftMouse> <nop>
imap <LeftMouse> <nop>
vmap <LeftMouse> <nop>

set textwidth=80

function! s:formatoptions()
    setlocal formatoptions+=nlj
    setlocal formatoptions-=o
endfunction

autocmd! BufNewFile,BufRead * call s:formatoptions()

augroup Binary
    au!
    au BufReadPre  *.bin let &bin=1
    au BufReadPost *.bin if &bin | %!xxd
    au BufReadPost *.bin set ft=xxd | endif
    au BufWritePre *.bin if &bin | %!xxd -r
    au BufWritePre *.bin endif
    au BufWritePost *.bin if &bin | %!xxd
    au BufWritePost *.bin set nomod | endif
augroup END
