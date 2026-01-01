" ~/.vimrc
" ----------------------------------------------------------

let s:plugin_enable = 1
" vim-plug automatic installation {{{
" ----------------------------------------------------------
if s:plugin_enable
  let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
  if empty(glob(data_dir . '/autoload/plug.vim'))
    silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  endif
endif
" }}}

" Plugin list {{{
" ----------------------------------------------------------
let s:plug_root = has('nvim') ? stdpath('data') . '/plugged/' : '~/.vim/plugged/'
if s:plugin_enable
  call plug#begin(expand(s:plug_root))

  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'
  Plug 'prabirshrestha/asyncomplete-emmet.vim'
  Plug 'prabirshrestha/asyncomplete-file.vim'
  Plug 'prabirshrestha/asyncomplete-tags.vim'
  Plug 'mechatroner/rainbow_csv'
  Plug 'mattn/emmet-vim'
  Plug 'AndrewRadev/tagalong.vim'
  Plug 'alvan/vim-closetag'
  Plug 'ap/vim-css-color'

  if !has('patch-9.1.0375') && !has('nvim-0.10')
    Plug 'tpope/vim-commentary'
  endif

  call plug#end()
endif
" }}}

" Plugin settings {{{
" ----------------------------------------------------------
function! s:IsLoaded(name) abort
  let l:path = expand(s:plug_root . a:name)
  return (&rtp =~ '\c' . a:name) && isdirectory(l:path)
endfunction

if s:plugin_enable
  " lsp servers {{{
  " ----------------------------------------------------------
  if s:IsLoaded('vim-lsp')
    if executable('pylsp')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'pylsp',
            \ 'cmd': {server_info->['pylsp']},
            \ 'allowlist': ['python'],
            \ })
    endif

    if executable('mojo')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'mojo-lsp-server',
            \ 'cmd': {server_info->['mojo-lsp-server']},
            \ 'allowlist': ['mojo'],
            \ })
    endif

    if executable('clangd')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'clangd',
            \ 'cmd': {server_info->['clangd', '--background-index', '--clang-tidy']},
            \ 'allowlist': ['c', 'cpp'],
            \ })
    endif

    if executable('rust-analyzer')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'rust-analyzer',
            \ 'cmd': {server_info->['rust-analyzer']},
            \ 'allowlist': ['rust'],
            \ })
    endif

    if executable('vscode-html-language-server')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'html-languageserver',
            \ 'cmd': {server_info->['vscode-html-language-server', '--stdio']},
            \ 'allowlist': ['html'],
            \ })
    endif

    if executable('vscode-css-language-server')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'css-languageserver',
            \ 'cmd': {server_info->['vscode-css-language-server', '--stdio']},
            \ 'allowlist': ['css', 'scss'],
            \ })
    endif

    if executable('vscode-json-language-server')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'json-languageserver',
            \ 'cmd': {server_info->['vscode-json-language-server', '--stdio']},
            \ 'allowlist': ['json'],
            \ })
    endif

    if executable('typescript-language-server')
      au User lsp_setup call lsp#register_server({
            \ 'name': 'typescript-language-server',
            \ 'cmd': {server_info->['typescript-language-server', '--stdio']},
            \ 'allowlist': ['javascript', 'javascriptreact', 'typescript', 'typescriptreact'],
            \ })
    endif
  endif
  " }}}

  " vim-lsp {{{
  " ----------------------------------------------------------
  if s:IsLoaded('vim-lsp')
    function! s:on_lsp_buffer_enabled() abort
      setlocal omnifunc=lsp#complete
      setlocal signcolumn=yes
      if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
      nmap <buffer> gd <plug>(lsp-definition)
      nmap <buffer> gs <plug>(lsp-document-symbol-search)
      nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
      nmap <buffer> gr <plug>(lsp-references)
      nmap <buffer> gi <plug>(lsp-implementation)
      nmap <buffer> gt <plug>(lsp-type-definition)
      nmap <buffer> <leader>rn <plug>(lsp-rename)
      nmap <buffer> [g <plug>(lsp-previous-diagnostic)
      nmap <buffer> ]g <plug>(lsp-next-diagnostic)
      nmap <buffer> K <plug>(lsp-hover)
      nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
      nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

      let g:lsp_format_sync_timeout = 1000
      autocmd! BufWritePre *.c,*.h,*.cpp,*.hpp,*.cc call execute('LspDocumentFormatSync')
      autocmd! BufWritePre *.py,*.mojo,*.rs call execute('LspDocumentFormatSync')
      autocmd! BufWritePre *.js,*.ts,*.jsx,*.tsx,*.html,*.css,*.scss,*.json call execute('LspDocumentFormatSync')
    endfunction

    augroup lsp_install
      au!
      " call s:on_lsp_buffer_enabled only for languages that has the server registered.
      autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
    augroup END

    let g:lsp_diagnostics_enabled = 1
    let g:lsp_diagnostics_virtual_text_enabled = 1
    let g:lsp_diagnostics_virtual_text_insert_mode_enabled = 0
    let g:lsp_diagnostics_virtual_text_delay = 200
    let g:lsp_diagnostics_virtual_text_prefix = "// "
    let g:lsp_diagnostics_virtual_text_align = "after"
    let g:lsp_diagnostics_virtual_text_padding_left = 2
    let g:lsp_diagnostics_virtual_text_wrap = "truncate"
    let g:lsp_diagnostics_virtual_text_tidy = 1
  endif
  " }}}

  " asyncomplete.vim {{{
  " ----------------------------------------------------------
  if s:IsLoaded('asyncomplete.vim')
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"
  endif
  " }}}

  " asyncomplete-emmet.vim {{{
  " ----------------------------------------------------------
  if s:IsLoaded('asyncomplete-emmet.vim')
    au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#emmet#get_source_options({
          \ 'name': 'emmet',
          \ 'whitelist': ['html'],
          \ 'completor': function('asyncomplete#sources#emmet#completor'),
          \ }))
  endif
  " }}}

  " asyncomplete-file.vim {{{
  " ----------------------------------------------------------
  if s:IsLoaded('asyncomplete-file.vim')
    au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
          \ 'name': 'file',
          \ 'allowlist': ['*'],
          \ 'priority': 10,
          \ 'completor': function('asyncomplete#sources#file#completor')
          \ }))
  endif
  " }}}

  " asyncomplete-tags.vim {{{
  " ----------------------------------------------------------
  if s:IsLoaded('asyncomplete-tags.vim')
    au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#tags#get_source_options({
          \ 'name': 'tags',
          \ 'allowlist': ['c'],
          \ 'completor': function('asyncomplete#sources#tags#completor'),
          \ 'config': {
          \    'max_file_size': 50000000,
          \  },
          \ }))
  endif
  " }}}

  " emmet-vim {{{
  " ----------------------------------------------------------
  if s:IsLoaded('emmet-vim')
    let g:user_emmet_mode='inv'
    " let g:user_emmet_install_global = 0
    " autocmd FileType html,css EmmetInstall
    let g:user_emmet_leader_key='e.'
  endif
  " }}}
endif
" }}}

" Options {{{
" ----------------------------------------------------------
filetype plugin indent on
syntax enable

let s:is_nvim = has('nvim')
if !s:is_nvim
  set encoding=UTF-8
  set guioptions-=T
  set nocompatible
endif

language C
set fileencoding=UTF-8
set fileencodings=UTF-8,euckr,cp949
set fileformats=unix
set langmenu=none
set nospell

set autoindent
set smartindent

set expandtab
set shiftwidth=2
set smarttab
set softtabstop=2
set tabstop=2

set backspace=2
set hidden
set hlsearch
set ignorecase
set incsearch
set mouse=a
set number
set smartcase
set wrapscan

set noshowcmd
set ruler
set showcmdloc=
set showmode
set wildignorecase
set wildmenu
set wildmode=list:longest,full

set cursorline
set cursorlineopt=number
set diffopt+=algorithm:histogram,vertical
set laststatus=2
set nocursorcolumn
set signcolumn=no

set splitbelow
set splitright

set foldmarker={{{,}}}
set foldmethod=marker
set showmatch

set list
set listchars=tab:»\ ,trail:·,extends:▶,precedes:◀,nbsp:␣
set textwidth=0
augroup group_colorcolumn
  autocmd!
  autocmd BufNewFile,BufRead * if &textwidth > 0 | set colorcolumn=+1 |
        \ else | set colorcolumn= | endif
augroup END

let &showbreak = '+++ '
set formatoptions=croqlnj
set linebreak
set sidescrolloff=5
set wrap

set complete+=.,t,i
set completeopt=menuone,noinsert,noselect,preview
set conceallevel=0
set nojoinspaces
set nrformats=alpha,octal,hex,bin,unsigned
set scrolloff=5
set shortmess+=c
set virtualedit=block

set belloff=all
set noerrorbells
set novisualbell
set t_vb=

set autoread
set isfname-==
set lazyredraw
set noautochdir
set updatetime=100

set path+=**
set tags=./tags;/

set clipboard=unnamed
if has('unnamedplus')
  set clipboard+=unnamedplus
endif

if !s:is_nvim
  let s:history_dir = $HOME . '/.vim/history/'
else
  let s:history_dir = $HOME . '/.config/nvim/history/'
endif

if !isdirectory(s:history_dir)
  call mkdir(s:history_dir, 'p', 0700)
endif

for dir in ['undo', 'backup', 'swap']
  if !isdirectory(s:history_dir . '/' . dir)
    call mkdir(s:history_dir . '/' . dir, 'p', 0700)
  endif
endfor

let &undodir = s:history_dir . '/undo'
set undofile
let &backupdir = s:history_dir . '/backup'
set backup
set writebackup
let &directory = s:history_dir . '/swap'
set noswapfile

if !s:is_nvim
  execute 'set viminfo+=n' . s:history_dir . '.viminfo'
else
  execute 'set shadafile=' . s:history_dir . 'main.shada'
endif

if exists('+smoothscroll')
  set smoothscroll
endif
if exists('+splitkeep')
  set splitkeep=screen
endif

" See: 05.5 'Adding a package' in *usr_05.txt*
packadd! matchit
packadd! cfilter

if !s:is_nvim
  if has('patch-9.1.0375') " Vim 9.1.0375+
    packadd! comment
  endif
  " if has('patch-9.1.0500') " Vim 9.1.0500+
  "   packadd! nohlsearch
  " endif
  if has('patch-9.1.0509') " Vim 9.1.0509+
    packadd! editorconfig
  endif
endif
" }}}

" KeyMappings {{{
" ----------------------------------------------------------
let mapleader = '\'

inoremap jk <ESC>
nnoremap , :
vnoremap , :
nnoremap j gj
nnoremap k gk
nnoremap 0 g0
nnoremap ^ g^
nnoremap $ g$

nnoremap <leader>y maggVG"+y`a
nnoremap <leader>= magg=G`a
nnoremap <S-u> <C-r>
nnoremap <leader>/ :noh<CR>
nnoremap <leader>v <C-v>
nnoremap [b :bprevious<CR>
nnoremap ]b :bnext<CR>
nnoremap [t :tabprevious<CR>
nnoremap ]t :tabnext<CR>

nnoremap <leader>w <C-w>
nnoremap <leader>1 <C-w>h
nnoremap <leader>2 <C-w>j
nnoremap <leader>3 <C-w>k
nnoremap <leader>4 <C-w>l

nnoremap <leader>5 <C-w>H
nnoremap <leader>6 <C-w>J
nnoremap <leader>7 <C-w>K
nnoremap <leader>8 <C-w>L

nnoremap <leader><leader>1 :vertical resize -5<CR>
nnoremap <leader><leader>2 :resize -5<CR>
nnoremap <leader><leader>3 :resize +5<CR>
nnoremap <leader><leader>4 :vertical resize +5<CR>

nnoremap <leader>] <C-]>
nnoremap <leader>t <C-t>
nnoremap <leader>wd :ls<cr>:b<space>
inoremap {<CR> {<CR>}<Esc>O
nnoremap Q <NOP>

" https://stackoverflow.com/questions/290465/how-to-paste-over-without-overwriting-register
xnoremap <expr> p 'pgv"'.v:register.'y`>'

nnoremap c "_c
vnoremap c "_c
nnoremap C "_C
vnoremap C "_C

nnoremap x "_x
vnoremap x "_x
nnoremap X "_X
vnoremap X "_X

nnoremap s "_s
vnoremap s "_s
nnoremap S "_S
vnoremap S "_S

nnoremap <leader>re :reg<CR>
nnoremap <leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>
vnoremap <leader>s y:<C-u>%s/\V<C-r>=escape(@", '/\')<CR>//g<Left><Left>
vnoremap * y:let @/ = '\V' . escape(@", '\/')<CR>
vnoremap # y:let @/ = '\V' . escape(@", '\/')<CR>

nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap gD gDzz
nnoremap G Gzz

inoremap <leader>2 <C-n>
nnoremap <leader>r :set relativenumber!<CR>
" }}}

" Colorscheme {{{
" ----------------------------------------------------------
let g:molokai_original = 0
let g:rehash256 = 0

if (getenv('COLORTERM') ==? 'truecolor') || has('gui_running')
  set termguicolors
else
  set t_Co=256
  if !s:is_nvim
    set t_ut=
  endif
endif

set background=dark
if &background == 'dark'
  try | colorscheme molokai | catch | colorscheme sorbet | catch | endtry
else
  try | colorscheme paper | catch | colorscheme retrobox | catch | endtry
endif
" }}}

" Statusline {{{
" ----------------------------------------------------------
function! s:SetupStatusLine() abort
  set statusline=
  let &statusline .= ' '

  if &diff
    set statusline+=%-20.50F
  else
    set statusline+=%f
  endif

  set statusline+=\ %h%m%r%w
  set statusline+=%=%<
  set statusline+=\ %l/%L,\ %3c
  " set statusline+=\ \|\ %2P
  " set statusline+=\ \|\ A:%03.3b\ H:%02.2B
  " set statusline+=\ \|\ b%n:w%{winnr()}
  let &statusline .= '%{&filetype !=# "" ? " \| " . &filetype : ""}'
  set statusline+=\ \|\ %{&fileencoding}[%{&fileformat}]
  let &statusline .= ' '
endfunction

call <SID>SetupStatusLine()
augroup group_status_line_updater
  autocmd!
  autocmd DiffUpdated * call <SID>SetupStatusLine()
augroup END
" }}}

" netrw (Tree explorer) {{{
" ----------------------------------------------------------
function! s:OpenNetrwAtCurrentFileDir() abort
  let l:current_file_dir = fnamemodify(expand('%:p'), ':h')
  let l:original_pwd = getcwd()
  execute 'cd ' . l:current_file_dir
  Lexplore
  execute 'cd ' . l:original_pwd
endfunction

nnoremap <leader>ef :Lexplore<CR>
nnoremap <Leader>ec :call <SID>OpenNetrwAtCurrentFileDir()<CR>

augroup group_netrw
  autocmd!
  autocmd FileType netrw setlocal bufhidden=wipe
augroup END

let g:netrw_keepdir = 1
let g:netrw_altv = 1
let g:netrw_banner = 1
let g:netrw_browse_split = 4
let g:netrw_liststyle = 3
let g:netrw_winsize = 100

let g:netrw_fastbrowse = 0
let g:netrw_localcopydircmd = 'cp -r'
" }}}

" FileType settings {{{
" ----------------------------------------------------------
augroup group_filetype_settings
  autocmd!
  autocmd FileType vim,sh,zsh setlocal ts=2 sw=2 sts=2 tw=0 et
  autocmd FileType c,cpp setlocal ts=2 sw=2 sts=2 tw=80 et cin
  autocmd FileType make setlocal ts=4 sw=4 noet
  autocmd FileType python,mojo setlocal ts=4 sw=4 sts=4 tw=80 et
  autocmd FileType gitcommit,gitrebase setlocal ts=2 sw=2 sts=2 tw=72 et
  autocmd FileType rust setlocal ts=4 sw=4 sts=4 tw=99 et
  autocmd FileType html,css,scss,javascript,javascriptreact,typescript,typescriptreact,json setlocal ts=2 sw=2 sts=2 tw=0 et
augroup END
" }}}

" Etc. {{{
" ----------------------------------------------------------
if !s:IsLoaded('asyncomplete.vim')
  inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
  inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
  inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
endif
augroup group_popup_menu_close
  autocmd!
  autocmd CompleteDone * if pumvisible() == 0 | pclose | endif
augroup END

augroup group_vim_diff
  autocmd!
  autocmd BufEnter * if &diff | syntax off | else | syntax on | endif
augroup END

function! s:TrimCarriageReturn() abort
  let l:save = winsaveview()
  keeppatterns %s/\r//g
  call winrestview(l:save)
endfunction

command! TrimCarriageReturn call <SID>TrimCarriageReturn()
augroup group_trim_carriage_return
  autocmd!
  autocmd BufWritePre * silent! TrimCarriageReturn
augroup END

function! s:TrimWhitespace() abort
  let l:save = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:save)
endfunction

command! TrimWhitespace call <SID>TrimWhitespace()
augroup group_trim_whitespace
  autocmd!
  autocmd BufWritePre * silent! TrimWhitespace
augroup END

function! s:ToggleQuickFix() abort
  if getqflist({'winid' : 0}).winid
    cclose
  else
    copen
  endif
endfunction
nnoremap <silent> <leader>qf :call <SID>ToggleQuickFix()<CR>
nnoremap [q :cprevious<CR>
nnoremap ]q :cnext<CR>

function! s:ToggleLocationList() abort
  if getloclist(0, {'winid' : 0}).winid
    lclose
  else
    try
      lopen
    catch /E776/
      echohl WarningMsg
      echo "Location List is empty for the current window."
      echohl None
    endtry
  endif
endfunction
nnoremap <silent> <leader>ll :call <SID>ToggleLocationList()<CR>
nnoremap [l :lprevious<CR>
nnoremap ]l :lnext<CR>

if !s:IsLoaded('vim-lsp')
  function! s:RunClangFormat() abort
    if !executable('clang-format')
      return
    endif

    let l:view = winsaveview()
    silent! %!clang-format -style=llvm

    if v:shell_error
      undo
      redraw
      echohl ErrorMsg | echo "clang-format failed to format the code." | echohl None
    endif

    call winrestview(l:view)
  endfunction

  augroup group_clang_format
    autocmd!
    autocmd BufWritePre *.c,*.h,*.cpp,*.hpp,*.cc call s:RunClangFormat()
  augroup END
endif
" }}}

" Grep & Find {{{
" ----------------------------------------------------------
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --glob\ '!.git/*'
  set grepformat=%f:%l:%c:%m
else
  set grepprg=grep\ -rnI\ --exclude-dir=.git\ $*
endif

function! s:GetProjectRoot() abort
  let l:git_dir = finddir('.git', '.;')

  if empty(l:git_dir)
    return expand('%:p:h')
  endif

  let l:git_path = fnamemodify(l:git_dir, ':p')
  let l:root = substitute(l:git_path, '[\\/]\.git[\\/]\=$', '', '')

  return l:root
endfunction

function! s:GrepFromRoot(args) abort
  let l:root = s:GetProjectRoot()
  execute 'silent grep! ' . a:args . ' ' . shellescape(l:root)
  copen
  redraw!
endfunction

command! -nargs=+ Grep call s:GrepFromRoot(<q-args>)
command! -nargs=+ GrepStr call s:GrepFromRoot('-F ' . <q-args>)

let g:fd_exe = executable('fd') ? 'fd' : (executable('fdfind') ? 'fdfind' : '')
if g:fd_exe != ''
  function! s:FindFile(args) abort
    let l:root = s:GetProjectRoot()
    let l:cmd = g:fd_exe . ' -i --hidden --absolute-path -E .git ' . shellescape(a:args) . ' ' . shellescape(l:root)
    let l:output = system(l:cmd)
    if empty(l:output) | return | endif
    cgetexpr l:output
    copen
    redraw!
  endfunction
  command! -nargs=1 FindFile call s:FindFile(<q-args>)
else
  function! s:FindFileFallback(args) abort
    let l:root = s:GetProjectRoot()
    let l:cmd = 'find ' . shellescape(l:root) . ' -not -path "*/.git/*" -iname ' . shellescape('*' . a:args . '*')
    cgetexpr system(l:cmd)
    copen
    redraw!
  endfunction
  command! -nargs=1 FindFile call s:FindFileFallback(<q-args>)
endif

nnoremap <leader>gp :Grep<SPACE>
nnoremap <leader>gr :GrepStr<SPACE>
nnoremap <leader>fp :Grep <C-R><C-W><CR>
nnoremap <leader>fr :GrepStr <C-R><C-W><CR>
nnoremap <leader>ff :FindFile<SPACE>
" }}}

" Code Runner {{{
" ----------------------------------------------------------
let s:run_commands = {
      \   'c':          'gcc -std=c17 -O2 -Wall {src} -o {exe} && {exe}',
      \   'cpp':        'g++ -std=c++17 -O2 -Wall {src} -o {exe} && {exe}',
      \   'rust':       'rustc {src} -o {exe} && {exe}',
      \   'python':     'python3 {src}',
      \   'mojo':       'mojo {src}',
      \   'javascript': 'node {src}',
      \ }

function! s:OpenInputFile() abort
  let l:input_file = expand('%:p:r') . ".in"
  execute 'split ' . fnameescape(l:input_file)
endfunction

function! s:RunCode() abort
  if &modified | write | endif

  if !has_key(s:run_commands, &filetype)
    echo "Unsupported file type: " . &filetype
    return
  endif

  let l:src = shellescape(expand('%:p'))
  let l:exe = shellescape(expand('%:p:r'))
  let l:input_file = expand('%:p:r') . ".in"

  let l:cmd = s:run_commands[&filetype]
  let l:cmd = substitute(l:cmd, '{src}', l:src, 'g')
  let l:cmd = substitute(l:cmd, '{exe}', l:exe, 'g')

  if filereadable(l:input_file)
    let l:cmd .= ' < ' . shellescape(l:input_file)
  endif

  if index(['c', 'cpp', 'rust'], &filetype) >= 0
    let l:cmd .= ' && rm -f ' . l:exe
  endif

  let l:clear_cmd = 'clear'
  execute '!' . l:clear_cmd . ' && ' . l:cmd
endfunction

augroup group_code_runner
  autocmd!
  autocmd FileType * nnoremap <buffer> <leader>x <NOP>
  autocmd FileType * nnoremap <buffer> <leader>z <NOP>
  autocmd FileType c,cpp,rust nnoremap <buffer> <leader>x :call <SID>RunCode()<CR>
  autocmd FileType c,cpp,rust nnoremap <buffer> <leader>z :call <SID>OpenInputFile()<CR>
  autocmd FileType python,mojo nnoremap <buffer> <leader>x :call <SID>RunCode()<CR>
  autocmd FileType python,mojo nnoremap <buffer> <leader>z :call <SID>OpenInputFile()<CR>
  autocmd FileType javascript nnoremap <buffer> <leader>x :call <SID>RunCode()<CR>
  autocmd FileType javascript nnoremap <buffer> <leader>z :call <SID>OpenInputFile()<CR>
augroup END
" }}}

" ----------------------------------------------------------
augroup group_MYVIMRC
  autocmd!
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END
" vim: set sw=2 ts=2 sts=2 et tw=0 foldmarker={{{,}}} foldmethod=marker:
