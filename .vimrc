" ~/.vimrc
" ----------------------------------------------------------
let s:is_nvim = has('nvim')

" Options {{{
" ----------------------------------------------------------
filetype plugin indent on
syntax enable

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

" nnoremap d "_d
" vnoremap d "_d
nnoremap D "_D
vnoremap D "_D

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
" }}}

" FileType settings {{{
" ----------------------------------------------------------
augroup group_filetype_settings
  autocmd!
  autocmd FileType vim,sh,zsh setlocal ts=2 sw=2 sts=2 tw=0 et
  autocmd FileType c setlocal ts=2 sw=2 sts=2 tw=80 et cin
  autocmd FileType make setlocal ts=4 sw=4 noet
  autocmd FileType python setlocal ts=4 sw=4 sts=4 tw=80 et
  autocmd FileType gitcommit,gitrebase setlocal ts=2 sw=2 sts=2 tw=72 et
augroup END
" }}}

" Etc. {{{
" ----------------------------------------------------------
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"
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

function! ToggleQuickFix()
  if getqflist({'winid' : 0}).winid
    cclose
  else
    copen
  endif
endfunction
nnoremap <silent> <leader>qf :call ToggleQuickFix()<CR>
nnoremap [q :cprevious<CR>
nnoremap ]q :cnext<CR>

function! ToggleLocationList()
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
nnoremap <silent> <leader>ll :call ToggleLocationList()<CR>
nnoremap [l :lprevious<CR>
nnoremap ]l :lnext<CR>
" }}}

" Grep & Find {{{
" ----------------------------------------------------------
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --glob\ '!.git/*'
  set grepformat=%f:%l:%c:%m
else
  set grepprg=grep\ -rnI\ --exclude-dir=.git\ $*
endif

command! -nargs=+ Grep execute 'silent grep! <args>' | copen | redraw!
command! -nargs=+ GrepStr execute 'silent grep! -F <args>' | copen | redraw!

let g:fd_exe = executable('fd') ? 'fd' : (executable('fdfind') ? 'fdfind' : '')
if g:fd_exe != ''
  execute "command! -nargs=1 FindFile cgetexpr system('" . g:fd_exe . " -i --hidden -E .git ' . shellescape(<q-args>)) | copen | redraw!"
else
  command! -nargs=1 FindFile cgetexpr system('find . -not -path "*/.git/*" -iname ' . shellescape('*' . <q-args> . '*')) | copen | redraw!
endif

nnoremap <leader>gp :Grep<SPACE>
nnoremap <leader>gr :GrepStr<SPACE>

nnoremap <leader>fp :Grep <C-R><C-W><CR>
nnoremap <leader>fr :GrepStr <C-R><C-W><CR>

nnoremap <leader>ff :FindFile<SPACE>
" }}}

" Code Runner {{{
" ----------------------------------------------------------
function! s:OpenInputFile()
  let l:input_file = expand('%:p:r') . ".in"
  execute 'vsplit ' . fnameescape(l:input_file)
endfunction

function! s:RunCode()
  write
  let l:src_path = shellescape(expand('%:p'))
  let l:exe_path = shellescape(expand('%:p:r'))
  let l:input_file = expand('%:p:r') . ".in"

  let l:compile_cmd = ""
  let l:cmd = ""
  let l:input_cmd = ""
  let l:cleanup_cmd = ""

  if filereadable(l:input_file)
    let l:input_cmd = " < " . shellescape(l:input_file)
  endif

  if &filetype == 'python'
    let l:cmd = "python3 " . l:src_path . l:input_cmd

  elseif &filetype == 'c'
    let l:compile_cmd = "cc -std=c17 -O2 -Wall " . l:src_path . " -o " . l:exe_path
    let l:cleanup_cmd = " && rm " . l:exe_path
    let l:cmd = l:compile_cmd . " && ". l:exe_path . l:input_cmd . l:cleanup_cmd
  endif

  if l:cmd != ""
    " execute 'clear'
    execute '!' . l:cmd
  else
    echo "Unsupported file type."
  endif
endfunction

augroup group_code_runner
  autocmd!
  autocmd FileType * nnoremap <buffer> <leader>x <NOP>
  autocmd FileType * nnoremap <buffer> <leader>z <NOP>
  autocmd FileType python,c nnoremap <buffer> <leader>x :call <SID>RunCode()<CR>
  autocmd FileType python,c nnoremap <buffer> <leader>z :call <SID>OpenInputFile()<CR>
augroup END
" }}}

" ----------------------------------------------------------
augroup group_MYVIMRC
  autocmd!
  autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END
" vim: set sw=2 ts=2 sts=2 et tw=0 foldmarker={{{,}}} foldmethod=marker:
