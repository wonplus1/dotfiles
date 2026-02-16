-- ~/.config/nvim/init.lua
-- ---------------------------------------------------------
vim.g.mapleader = '\\'
vim.g.maplocalleader = '\\'

-- Disable built-in plugins {{{
-- ---------------------------------------------------------
vim.g.loaded_tutor_mode_plugin = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
-- }}}

-- Plugins {{{
-- ---------------------------------------------------------
-- Install lazy.nvim {{{
-- ~/.local/share/nvim/lazy/
-- ---------------------------------------------------------
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out =
    vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
-- }}}

-- Setup plugins {{{
-- ---------------------------------------------------------
require('lazy').setup {
  spec = {
    -- nvim-treesitter & modules {{{
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      lazy = false,
      build = ':TSUpdate',
    },
    {
      'MeanderingProgrammer/treesitter-modules.nvim',
      dependencies = { 'nvim-treesitter/nvim-treesitter' },
      opts = {
        -- stylua: ignore start
        -- list of parser names, or 'all', that must be installed
        ensure_installed = {
          'c', 'lua', 'vim', 'vimdoc', 'query', 'luadoc', 'markdown', 'markdown_inline', 'regex',
          'gitcommit', 'git_rebase', 'diff',
          'bash', 'zsh',
          'html', 'css', 'scss',
          'javascript', 'typescript', 'jsx', 'tsx',
          'json', 'json5', 'graphql', 'jsdoc',
          'toml', 'yaml', 'xml', 'csv', 'sql', 'dockerfile',
          'cpp', 'python', 'rust',
        },

        -- list of parser names, or 'all', to ignore installing
        ignore_install = {},
        -- stylua: ignore end

        -- install parsers in ensure_installed synchronously
        sync_install = false,
        -- automatically install missing parsers when entering buffer
        auto_install = true,

        fold = { disable = true },

        highlight = {
          enable = true,
          -- setting this to true will run `:h syntax` and tree-sitter at the same time
          -- set this to `true` if you depend on 'syntax' being enabled
          -- using this option may slow down your editor, and duplicate highlights
          -- instead of `true` it can also be a list of languages
          additional_vim_regex_highlighting = false,
        },

        incremental_selection = {
          enable = true,
          -- set value to `false` to disable individual mapping
          -- node_decremental captures both node_incremental and scope_incremental
          keymaps = {
            init_selection = '<C-space>',
            node_incremental = '<C-space>',
            scope_incremental = false,
            node_decremental = '<bs>',
          },
        },

        indent = { enable = true },
      },
    },
    -- }}}

    -- nvim-lspconfig {{{
    {
      'neovim/nvim-lspconfig',
      dependencies = {
        'saghen/blink.cmp',
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'WhoIsSethDaniel/mason-tool-installer.nvim',
      },
      config = function()
        require('mason').setup()

        require('mason-tool-installer').setup {
          ensure_installed = {
            'prettier',
            'shfmt',
            'stylua',
          },
        }

        local servers = {
          bashls = {},
          biome = {},
          clangd = {},
          cssls = {},
          dockerls = {},
          emmet_language_server = {},
          html = {},
          lua_ls = {},
          ruff = {},
          rust_analyzer = {},
          tailwindcss = {},
          taplo = {},
          ty = {},
          vtsls = {},
          yamlls = {},
        }

        require('mason-lspconfig').setup {
          ensure_installed = vim.tbl_keys(servers),
          automatic_installation = true,
        }

        local has_blink, blink = pcall(require, 'blink.cmp')
        local base_capabilities = has_blink and blink.get_lsp_capabilities()
          or vim.lsp.protocol.make_client_capabilities()

        vim.lsp.config('clangd', {
          capabilities = base_capabilities,
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=LLVM',
            '--offset-encoding=utf-16',
          },
          root_markers = {
            '.clangd',
            '.clang-tidy',
            '.clang-format',
            'compile_commands.json',
            'compile_flags.txt',
            'CMakeLists.txt',
            'Makefile',
            '.git',
          },
        })

        vim.lsp.config('vtsls', {
          capabilities = base_capabilities,
          settings = {
            typescript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
          root_markers = { 'tsconfig.json', 'package.json', '.git' },
        })

        vim.lsp.config('rust_analyzer', {
          capabilities = base_capabilities,
          settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              check = {
                allFeatures = true,
                command = 'clippy',
                extraArgs = { '--no-deps' },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                  ['async-recursion'] = { 'async_recursion' },
                },
              },
              inlayHints = {
                bindingModeHints = { enable = true },
                chainingHints = { enable = true },
                closingBraceHints = { enable = true, minLines = 25 },
                parameterHints = { enable = true },
                typeHints = { enable = true },
              },
              diagnostics = {
                disabled = { 'unresolved-proc-macro' },
                enable = true,
              },
            },
          },
          root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
        })

        vim.lsp.config('lua_ls', {
          capabilities = base_capabilities,
          settings = {
            Lua = {
              runtime = { version = 'LuaJIT' },
              diagnostics = { globals = { 'vim', 'Snacks' } },
              workspace = {
                library = {
                  vim.env.VIMRUNTIME,
                },
                checkThirdParty = false,
              },
              format = { enable = false },
              telemetry = { enable = false },
            },
          },
          root_markers = { '.luarc.json', '.stylua.toml', '.git' },
        })

        vim.lsp.config('ruff', {
          capabilities = base_capabilities,
          root_markers = { 'pyproject.toml', 'setup.py', '.git' },
        })
        vim.lsp.config('ty', {
          capabilities = base_capabilities,
          root_markers = { 'pyproject.toml', 'setup.py', '.git' },
        })

        for server_name, _ in pairs(servers) do
          if not vim.lsp.config[server_name] then
            vim.lsp.config(server_name, { capabilities = base_capabilities })
          end
          vim.lsp.enable(server_name)
        end

        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then return end

            local has_conform, _ = pcall(require, 'conform')
            if not has_conform then
              if client.supports_method 'textDocument/formatting' then
                vim.api.nvim_create_autocmd('BufWritePre', {
                  buffer = args.buf,
                  callback = function()
                    vim.lsp.buf.format { bufnr = args.buf, id = client.id, timeout_ms = 2000 }
                  end,
                })
              end
            end

            -- stylua: ignore start
            -- nvim-lspconfig (key-mapping) {{{
            local function map(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
            end

            -- map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
            -- map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
            -- map("n", "gr", vim.lsp.buf.references, "References")
            -- map("n", "gI", vim.lsp.buf.implementation, "Goto Implementation")
            -- map("n", "gy", vim.lsp.buf.type_definition, "Goto Type Definition")
            -- map("n", "gai", vim.lsp.buf.incoming_calls, "Calls Incoming")
            -- map("n", "gao", vim.lsp.buf.outgoing_calls, "Calls Outgoing")
            -- map("n", "<leader>ss", vim.lsp.buf.document_symbol, "LSP Symbols (Document)")
            -- map("n", "<leader>sS", vim.lsp.buf.workspace_symbol, "LSP Symbols (Workspace)")
            map("n", "gd", function() Snacks.picker.lsp_definitions() end, "Goto Definition")
            map("n", "gD", function() Snacks.picker.lsp_declarations() end, "Goto Declaration")
            map("n", "gr", function() Snacks.picker.lsp_references() end, "References")
            map("n", "gI", function() Snacks.picker.lsp_implementations() end, "Goto Implementation")
            map("n", "gy", function() Snacks.picker.lsp_type_definitions() end, "Goto Type Definition")
            map("n", "gai", function() Snacks.picker.lsp_incoming_calls() end, "Calls Incoming")
            map("n", "gao", function() Snacks.picker.lsp_outgoing_calls() end, "Calls Outgoing")
            map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, "LSP Symbols (Document)")
            map("n", "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, "LSP Symbols (Workspace)")

            map("n", "K", vim.lsp.buf.hover, "Hover Documentation")
            map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")

            map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Actions")
            map("n", "<leader>cr", vim.lsp.buf.rename, "Rename Symbol")
            -- map("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, "Format Code")
            map("n", "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, "Format Code")
            map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")

            if client.supports_method("textDocument/inlayHint") then
              map("n", "<leader>h", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf })) end, "Toggle Inlay Hints")
            end

            if client.name == "clangd" then
              map("n", "<leader>cs", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header")
            end

            if client.supports_method("textDocument/documentHighlight") then
              local group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
              vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                group = group,
                buffer = args.buf,
                callback = vim.lsp.buf.document_highlight,
              })
              vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                group = group,
                buffer = args.buf,
                callback = vim.lsp.buf.clear_references,
              })
            end
            -- }}}
            -- stylua: ignore end
          end,
        })

        -- stylua: ignore start
        vim.keymap.set( 'n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, { desc = 'Prev Diagnostic' })
        vim.keymap.set( 'n', ']d', function() vim.diagnostic.jump { count = 1, float = true } end, { desc = 'Next Diagnostic' })
        -- stylua: ignore end
      end,
    },
    -- }}}

    -- blink.cmp {{{
    {
      'saghen/blink.cmp',
      build = 'cargo build --release',
      version = '*',
      dependencies = 'rafamadriz/friendly-snippets',

      opts = {
        keymap = { preset = 'super-tab' },
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = 'mono',
        },
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer' },
        },
        signature = { enabled = true },
      },
    },
    -- }}}

    -- conform.nvim {{{
    {
      'stevearc/conform.nvim',
      event = { 'BufWritePre' },
      cmd = { 'ConformInfo' },

      opts = {
        formatters_by_ft = {
          sh = { 'shfmt' },
          bash = { 'shfmt' },
          zsh = { 'shfmt' },

          javascript = { 'biome', 'prettier', stop_after_first = true },
          typescript = { 'biome', 'prettier', stop_after_first = true },
          javascriptreact = { 'biome', 'prettier', stop_after_first = true },
          typescriptreact = { 'biome', 'prettier', stop_after_first = true },
          json = { 'biome', 'prettier', stop_after_first = true },
          jsonc = { 'biome', 'prettier', stop_after_first = true },
          -- biome.jsonc: { "html": { "formatter": { "enabled": true }, "linter": { "enabled": true }, "assist": { "enabled": true } } }
          html = { 'biome', 'prettier', stop_after_first = true },
          css = { 'biome', 'prettier', stop_after_first = true },
          scss = { 'prettier' },
          yaml = { 'prettier' },
          graphql = { 'biome', 'prettier', stop_after_first = true },
          markdown = { 'prettier' },
          ['markdown.inline'] = { 'prettier' },

          lua = { 'stylua' },
          toml = { 'taplo' },
        },

        format_on_save = {
          timeout_ms = 500,
          lsp_format = 'fallback',
        },
        formatters = {
          prettier = {
            prepend_args = { '--html-whitespace-sensitivity', 'ignore' },
          },
        },
      },
    },
    -- }}}

    -- oil.nvim {{{
    {
      'stevearc/oil.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      lazy = false,
      opts = {
        default_file_explorer = true,
        delete_to_trash = true,
        columns = {
          'icon',
          'permissions',
          'size',
          'mtime',
        },
        win_options = {
          signcolumn = 'yes:2',
        },
        view_options = {
          show_hidden = true,
        },
        float = {
          padding = 2,
          max_width = 100,
          max_height = 0.8,
          border = 'rounded',
          win_options = {
            winblend = 10,
            signcolumn = 'yes:2',
          },
        },
      },
      keys = {
        { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
        { '<leader>-', function() require('oil').toggle_float() end, desc = 'Open Oil (Floating)' },
      },
    },
    -- }}}

    -- oil-git-status.nvim {{{
    {
      'refractalize/oil-git-status.nvim',
      dependencies = {
        'stevearc/oil.nvim',
      },
      config = true,
    },
    -- }}}

    -- snacks.nvim {{{
    {
      'folke/snacks.nvim',
      priority = 1000,
      lazy = false,
      ---@type snacks.Config
      opts = {
        input = { enabled = true },
        picker = { enabled = true, hidden = true, ignored = true },
        terminal = { enabled = true },
        bigfile = { enabled = true },
        dashboard = { enabled = true },
        explorer = {
          enabled = true,
          replace_netrw = false,
          hidden = true,
          ignored = true,
          trash = true,
        },
        indent = { enabled = true, animate = { enabled = true } },
        notifier = { enabled = true, timeout = 3000 },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = false },
        statuscolumn = { enabled = false },
        words = { enabled = true },
        styles = { notification = { wo = { wrap = true } } },
      },

      keys = { -- {{{
        -- stylua: ignore start

        -- Top Pickers & Explorer
        { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files", },
        { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers", },
        { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep", },
        { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History", },
        { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History", },
        { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer", },

        -- find
        { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers", },
        { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File", },
        { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files", },
        { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files", },
        { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects", },
        { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent", },

        -- git
        { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Git Branches", },
        { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log", },
        { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line", },
        { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status", },
        { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash", },
        -- { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)", },
        { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File", },

        -- gh
        { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)", },
        { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)", },
        { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)", },
        { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)", },

        -- Grep
        { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines", },
        { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers", },
        { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep", },
        { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" }, },

        -- search
        { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers", },
        { "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History", },
        { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds", },
        { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines", },
        { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History", },
        { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands", },
        { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics", },
        { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics", },
        { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages", },
        { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights", },
        { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons", },
        { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps", },
        { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps", },
        { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List", },
        { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks", },
        { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages", },
        { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec", },
        { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List", },
        { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume", },
        { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History", },
        { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes", },

        -- Other
        { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode", },
        { "<leader>Z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom", },
        { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer", },
        { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer", },
        { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History", },
        { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer", },
        { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", },
        { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" }, },
        { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit", },
        { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications", },

        { "<c-/>", function() Snacks.terminal() end, desc = "Toggle Terminal", },
        { "<c-_>", function() Snacks.terminal() end, desc = "which_key_ignore", },

        { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" }, },
        { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" }, },

        {
          "<leader>N", desc = "Neovim News",
          function()
            Snacks.win({
              file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
              width = 0.6,
              height = 0.6,
              wo = { spell = false, wrap = false, signcolumn = "yes", statuscolumn = " ", conceallevel = 3, },
            })
          end,
        },
        -- stylua: ignore end
      }, -- }}}

      init = function()
        vim.api.nvim_create_autocmd('User', {
          pattern = 'VeryLazy',
          callback = function()
            -- Setup some globals for debugging (lazy-loaded)
            _G.dd = function(...) Snacks.debug.inspect(...) end
            _G.bt = function() Snacks.debug.backtrace() end

            -- Override print to use snacks for `:=` command
            if vim.fn.has 'nvim-0.11' == 1 then
              vim._print = function(_, ...) dd(...) end
            else
              vim.print = _G.dd
            end

            -- Create some toggle mappings
            Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
            Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
            Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
            Snacks.toggle.diagnostics():map '<leader>ud'
            Snacks.toggle.line_number():map '<leader>ul'
            Snacks.toggle
              .option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
              :map '<leader>uc'
            Snacks.toggle.treesitter():map '<leader>uT'
            Snacks.toggle
              .option('background', { off = 'light', on = 'dark', name = 'Dark Background' })
              :map '<leader>ub'
            Snacks.toggle.inlay_hints():map '<leader>uh'
            Snacks.toggle.indent():map '<leader>ug'
            Snacks.toggle.dim():map '<leader>uD'
          end,
        })
      end,
    },
    -- }}}

    -- flash.nvim {{{
    {
      'folke/flash.nvim',
      event = 'VeryLazy',
      ---@type Flash.Config
      opts = {},
      -- stylua: ignore start
      keys = {
        { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
        { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter', },
        { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
        { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search', },
        { '<c-s>', mode = { 'c' }, function() require('flash').toggle() end, desc = 'Toggle Flash Search', },
      },
      -- stylua: ignore end
    },
    -- }}}

    -- gitsigns.nvim {{{
    {
      'lewis6991/gitsigns.nvim',
      opts = {
        signs = {
          add = { text = '┃' },
          change = { text = '┃' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
          untracked = { text = '┆' },
        },
        current_line_blame = true,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            if type(opts) == 'string' then opts = { desc = opts } end

            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          map('n', ']h', function()
            if vim.wo.diff then return ']h' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = 'Next Hunk' })

          map('n', '[h', function()
            if vim.wo.diff then return '[h' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true, desc = 'Prev Hunk' })

          map('n', '<leader>hs', gs.stage_hunk, 'Stage Hunk')
          map('n', '<leader>hr', gs.reset_hunk, 'Reset Hunk')
          map('n', '<leader>hp', gs.preview_hunk, 'Preview Hunk')
          map('n', '<leader>hb', function() gs.blame_line { full = true } end, 'Blame Line')
          map('n', '<leader>hd', gs.diffthis, 'Diff This')
        end,
      },
    },
    -- }}}

    -- diffview.nvim {{{
    {
      'sindrets/diffview.nvim',

      config = function()
        vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Git Diffview Open' })
        vim.keymap.set(
          'n',
          '<leader>gh',
          '<cmd>DiffviewFileHistory %<cr>',
          { desc = 'Current File History' }
        )
        vim.keymap.set('n', '<leader>gx', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' })
      end,
    },
    -- }}}

    -- markdown-preview.nvim {{{
    {
      'iamcco/markdown-preview.nvim',
      cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
      build = 'cd app && yarn install',
      ft = { 'markdown' },

      init = function() vim.g.mkdp_filetypes = { 'markdown' } end,
    },
    -- }}}

    -- nvim-highlight-colors {{{
    {
      'brenoprata10/nvim-highlight-colors',
      event = 'VeryLazy',
      opts = {
        ---Render style
        ---@usage 'background'|'foreground'|'virtual'
        render = 'virtual',

        ---Set virtual symbol (requires render to be set to 'virtual')
        virtual_symbol = '■',

        ---Set virtual symbol suffix (defaults to '')
        virtual_symbol_prefix = '',

        ---Set virtual symbol suffix (defaults to ' ')
        virtual_symbol_suffix = ' ',

        ---Set virtual symbol position()
        ---@usage 'inline'|'eol'|'eow'
        ---inline mimics VS Code style
        ---eol stands for `end of column` - Recommended to set `virtual_symbol_suffix = ''` when used.
        ---eow stands for `end of word` - Recommended to set `virtual_symbol_prefix = ' ' and virtual_symbol_suffix = ''` when used.
        virtual_symbol_position = 'inline',

        ---Highlight hex colors, e.g. '#FFFFFF'
        enable_hex = true,

        ---Highlight short hex colors e.g. '#fff'
        enable_short_hex = true,

        ---Highlight rgb colors, e.g. 'rgb(0 0 0)'
        enable_rgb = true,

        ---Highlight hsl colors, e.g. 'hsl(150deg 30% 40%)'
        enable_hsl = true,

        ---Highlight ansi colors, e.g '\033[0;34m'
        enable_ansi = true,

        ---Highlight xterm 256 (8bit) colors, e.g '\033[38;5;118m'
        enable_xterm256 = true,

        ---Highlight xterm True Color (24bit) colors, e.g '\033[38;2;118;64;90m'
        enable_xtermTrueColor = true,

        -- Highlight hsl colors without function, e.g. '--foreground: 0 69% 69%;'
        enable_hsl_without_function = true,

        ---Highlight CSS variables, e.g. 'var(--testing-color)'
        enable_var_usage = true,

        ---Highlight named colors, e.g. 'green'
        enable_named_colors = true,

        ---Highlight tailwind colors, e.g. 'bg-blue-500'
        enable_tailwind = false,

        ---Set custom colors
        ---Label must be properly escaped with '%' to adhere to `string.gmatch`
        --- :help string.gmatch
        custom_colors = {
          { label = '%-%-theme%-primary%-color', color = '#0f1219' },
          { label = '%-%-theme%-secondary%-color', color = '#5a5d64' },
        },

        -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
        exclude_filetypes = {},
        exclude_buftypes = {},
        -- Exclude buffer from highlighting e.g. 'exclude_buffer = function(bufnr) return vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr)) > 1000000 end'
        exclude_buffer = function(bufnr) end,
      },
    },
    -- }}}

    -- nvim-ts-autotag {{{
    {
      'windwp/nvim-ts-autotag',
      opts = {},
      event = { 'BufReadPre', 'BufNewFile' },
    },
    -- }}}

    -- ts-comments.nvim {{{
    {
      'folke/ts-comments.nvim',
      opts = {},
      event = 'VeryLazy',
      enabled = vim.fn.has 'nvim-0.10.0' == 1,
    },
    -- }}}

    -- lualine.nvim {{{
    {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' },
      opts = {
        options = {
          theme = 'auto',
        },
      },
    },
    -- }}}

    -- nvim-autopairs {{{
    {
      'windwp/nvim-autopairs',
      event = 'InsertEnter',
      config = true,
      opts = {},
    },
    -- }}}

    { 'nvim-tree/nvim-web-devicons' },
    { 'tpope/vim-surround' },
    { 'tpope/vim-fugitive' },

    -- { "tomasr/molokai", name = "molokai", priority = 1000 },
    -- { "yorickpeterse/vim-paper", name = "paper", event = "VeryLazy" },
    { 'rose-pine/neovim', name = 'rose-pine' },
    { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  },

  install = { colorscheme = { 'default' } },
  checker = { enabled = true },
  performance = {
    rtp = {
      -- Disable built-in plugins
      disabled_plugins = {
        -- 'editorconfig',
        'gzip',
        -- 'man',
        -- 'matchit',
        'matchparen',
        'netrwPlugin',
        -- 'osc52',
        'rplugin',
        -- 'shada',
        'spellfile',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}
-- }}}
-- }}}

-- Options {{{
-- ---------------------------------------------------------
vim.g.editorconfig = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.textwidth = 0

vim.opt.ignorecase = true
vim.opt.joinspaces = false
vim.opt.smartcase = true
vim.opt.smarttab = true
vim.opt.wrapscan = true

vim.opt.cmdheight = 1
vim.opt.colorcolumn = '+1'
vim.opt.cursorcolumn = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '·', extends = '»', precedes = '«', nbsp = '░' }
vim.opt.fillchars = {
  vert = '│',
  eob = ' ',
  fold = '-',
  foldopen = '',
  foldsep = ' ',
  foldclose = '',
  diff = '╱',
  stl = ' ',
  stlnc = ' ',
}
vim.opt.number = true
vim.opt.shortmess:append 'c'
vim.opt.showcmd = false
vim.opt.showmode = true
vim.opt.signcolumn = 'number'
vim.opt.statuscolumn = ''
vim.opt.termguicolors = true

vim.opt.display = 'lastline'
vim.opt.inccommand = 'split'
vim.opt.linebreak = true
vim.opt.scrolloff = 8
vim.opt.showbreak = '+++ '
vim.opt.sidescrolloff = 8
vim.opt.smoothscroll = true
vim.opt.splitbelow = true
vim.opt.splitkeep = 'screen'
vim.opt.splitright = true
vim.opt.virtualedit = 'block'
vim.opt.wrap = false

vim.opt.autochdir = false
vim.opt.autoread = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.fileencodings = 'utf-8,euckr,cp949,latin1'
vim.opt.isfname:remove '='
vim.opt.langmenu = 'none'
vim.opt.lazyredraw = false
vim.opt.modeline = false
vim.opt.mouse = 'a'
vim.opt.synmaxcol = 250
vim.opt.tags = './tags;~'
vim.opt.updatetime = 100

vim.opt.wildignorecase = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:longest,full'
vim.opt.foldmarker = '{{{,}}}'
vim.opt.foldmethod = 'marker'
vim.opt.formatoptions = 'tcroqnlj'
vim.opt.showmatch = true

vim.opt.belloff = 'all'
vim.opt.diffopt:append { 'algorithm:histogram', 'vertical' }
vim.opt.nrformats = 'alpha,octal,hex,bin,unsigned'
-- }}}

-- History {{{
-- ---------------------------------------------------------
local state_dir = vim.fn.stdpath 'state' -- ~/.local/state/nvim
local history_dir = state_dir .. '/history/'
local sub_dirs = { 'undo', 'backup', 'swap', 'view' }

for _, dir in ipairs(sub_dirs) do
  local path = history_dir .. dir
  if vim.fn.isdirectory(path) == 0 then vim.fn.mkdir(path, 'p', 448) end
end

vim.opt.undodir = history_dir .. 'undo'
vim.opt.backupdir = history_dir .. 'backup'
vim.opt.directory = history_dir .. 'swap'
vim.opt.viewdir = history_dir .. 'view'
vim.opt.shadafile = history_dir .. 'main.shada'

vim.opt.undofile = true
vim.opt.backup = true
vim.opt.writebackup = true
vim.opt.swapfile = false
-- }}}

-- ColorScheme {{{
-- ---------------------------------------------------------
vim.opt.background = 'dark'
-- vim.cmd.colorscheme("molokai")
-- vim.api.nvim_set_hl(0, "SpecialKey", { italic = true })

local function apply_molokai_overrides()
  vim.api.nvim_set_hl(0, 'StatusLine', { fg = '#f8f8f2', bg = '#455354' })
  vim.api.nvim_set_hl(0, 'StatusLineNC', { fg = '#BCBCBC', bg = '#080808' })
  vim.api.nvim_set_hl(0, 'WinSeparator', { fg = '#333333', bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'VertSplit', { link = 'WinSeparator' })
end

local function remove_all_italics()
  local highlights = vim.api.nvim_get_hl(0, {})

  for group_name, settings in pairs(highlights) do
    if settings.italic then
      local new_settings = vim.tbl_extend('force', settings, { italic = false })
      vim.api.nvim_set_hl(0, group_name, new_settings)
    end
  end
end

local function remove_all_bold()
  local highlights = vim.api.nvim_get_hl(0, {})

  for group_name, settings in pairs(highlights) do
    if settings.bold then
      local new_settings = vim.tbl_extend('force', settings, { bold = false })
      vim.api.nvim_set_hl(0, group_name, new_settings)
    end
  end
end

local theme_augroup = vim.api.nvim_create_augroup('ThemeCustomization', { clear = true })
vim.api.nvim_create_autocmd('ColorScheme', {
  group = theme_augroup,
  pattern = '*',
  callback = function()
    remove_all_italics()
    -- remove_all_bold()

    local current_theme = vim.g.colors_name or ''
    if current_theme == 'molokai' then apply_molokai_overrides() end

    local has_lualine, _ = pcall(require, 'lualine')
    if has_lualine then
      local target_theme = 'auto'
      if current_theme == 'molokai' then target_theme = 'gruvbox' end
      require('lualine').setup {
        options = {
          theme = target_theme,
          globalstatus = false,
        },
      }
    end
  end,
  desc = 'Remove italics globally and apply theme-specific overrides',
})

local function try_colorscheme(themes)
  for _, theme in ipairs(themes) do
    if pcall(vim.cmd.colorscheme, theme) then return true end
  end
  return false
end
if vim.o.background == 'dark' then
  if not try_colorscheme { 'molokai', 'catppuccin-mocha', 'rose-pine', 'default' } then
    vim.notify('⚠️ No dark themes found. Using Neovim default.', vim.log.levels.WARN)
  end
else
  if not try_colorscheme { 'paper', 'default' } then
    vim.notify('⚠️ No light themes found. Using Neovim default.', vim.log.levels.WARN)
  end
end
-- }}}

-- Statusline {{{
-- ---------------------------------------------------------
local function setup_custom_statusline()
  local has_lualine, _ = pcall(require, 'lualine')
  if has_lualine then return end

  _G.MyConfig = _G.MyConfig or {}
  _G.MyConfig.minimal_statusline = function()
    local path = vim.wo.diff and '%<%-20.50F' or '%f'
    return ' ' .. path .. ' %m%r %= %< %l/%L, %3c '
  end
  vim.opt.statusline = '%!v:lua.MyConfig.minimal_statusline()'
end
setup_custom_statusline()
-- }}}

-- key-mapping {{{
-- ---------------------------------------------------------
vim.keymap.set('i', 'jk', '<ESC>')
vim.keymap.set({ 'n', 'v' }, ',', ':')
vim.keymap.set('n', '<S-u>', '<C-r>')
vim.keymap.set('n', 'Q', '<NOP>')

vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', '0', 'g0')
vim.keymap.set('n', '^', 'g^')
vim.keymap.set('n', '$', 'g$')

vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

vim.keymap.set('n', 'n', 'nzz')
vim.keymap.set('n', 'N', 'Nzz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')
vim.keymap.set('n', 'gD', 'gDzz')
vim.keymap.set('n', 'G', 'Gzz')

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', '<leader>y', 'maggVGy`a')
vim.keymap.set('n', '<leader>=', 'magg=G`a')
vim.keymap.set('n', '<leader>v', '<C-v>')
vim.keymap.set('i', '{<CR>', '{<CR>}<Esc>O')
vim.keymap.set('n', '<leader>b', '<C-^>')
vim.keymap.set('n', '<leader>bw', '<cmd>bwipeout<CR>')
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<CR>')
vim.keymap.set('n', '<leader>ls', '<cmd>buffers!<CR>')

local blackhole_keys = { 'c', 'C', 'x', 'X', 's', 'S' }
for _, key in ipairs(blackhole_keys) do
  vim.keymap.set({ 'n', 'v' }, key, '"_' .. key)
end

vim.keymap.set('x', 'p', [['pgv"'.v:register.'y`>']], { expr = true })
vim.keymap.set('n', '<leader>rs', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]])
vim.keymap.set('v', '<leader>rs', [[y:<C-u>%s/\V<C-r>=escape(@", '/\')<CR>//g<Left><Left>]])
vim.keymap.set('v', '*', [[y:let @/ = '\V' .. escape(@", '\/')<CR>]])
vim.keymap.set('v', '#', [[y:let @/ = '\V' .. escape(@", '\/')<CR>]])

vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { silent = true })
vim.keymap.set('n', '[t', '<cmd>tabprevious<CR>', { silent = true })
vim.keymap.set('n', ']t', '<cmd>tabnext<CR>', { silent = true })

vim.keymap.set('n', '<leader>w', '<C-w>')
vim.keymap.set('n', '<leader>1', '<C-w>h')
vim.keymap.set('n', '<leader>2', '<C-w>j')
vim.keymap.set('n', '<leader>3', '<C-w>k')
vim.keymap.set('n', '<leader>4', '<C-w>l')
vim.keymap.set('n', '<leader>5', '<C-w>H')
vim.keymap.set('n', '<leader>6', '<C-w>J')
vim.keymap.set('n', '<leader>7', '<C-w>K')
vim.keymap.set('n', '<leader>8', '<C-w>L')
vim.keymap.set('n', '<leader><leader>1', '<cmd>vertical resize -20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>2', '<cmd>resize -20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>3', '<cmd>resize +20<CR>', { silent = true })
vim.keymap.set('n', '<leader><leader>4', '<cmd>vertical resize +20<CR>', { silent = true })
-- }}}

-- Etc. {{{
-- Trim carriage return {{{
local is_wsl = vim.fn.has 'wsl' == 1

local function trim_carriage_return()
  local save_view = vim.fn.winsaveview()
  vim.cmd [[silent! keeppatterns %s/\r//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimCarriageReturn', trim_carriage_return, {
  desc = 'Remove carriage return (\r) characters from the current buffer',
})

if is_wsl then
  local trim_group = vim.api.nvim_create_augroup('WslTrimGroup', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = trim_group,
    pattern = '*',
    callback = function() trim_carriage_return() end,
    desc = 'Automatically trim \r on save in WSL',
  })
end
-- }}}

-- Trim trailing whitespace {{{
local function trim_trailing_whitespace()
  local save_view = vim.fn.winsaveview()
  -- 🚀 Remove trailing whitespace at the end of lines without affecting search history
  vim.cmd [[silent! keeppatterns %s/\s\+$//e]]
  vim.fn.winrestview(save_view)
end

vim.api.nvim_create_user_command('TrimWhitespace', trim_trailing_whitespace, {
  desc = 'Remove trailing whitespace from the current buffer',
})

local whitespace_group = vim.api.nvim_create_augroup('TrimWhitespaceGroup', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = whitespace_group,
  pattern = '*',
  callback = function() trim_trailing_whitespace() end,
  desc = 'Automatically trim trailing whitespace on save',
})
-- }}}

-- Highlight on yank {{{
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  callback = function() vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 } end,
})
-- }}}

-- Toggle some options {{{
-- Toggle Global Statusline (laststatus 2 <-> 3)
local function toggle_global_statusline()
  if vim.opt.laststatus:get() == 3 then
    vim.opt.laststatus = 2
    print '✅ Local Statusline (laststatus=2)'
  else
    vim.opt.laststatus = 3
    print '🚀 Global Statusline (laststatus=3)'
  end
end
vim.keymap.set(
  'n',
  '<leader><leader>s',
  toggle_global_statusline,
  { desc = 'Toggle Global Statusline' }
)

-- Toggle cmdheight (0 <-> 1)
local function toggle_cmdheight()
  if vim.opt.cmdheight:get() == 1 then
    vim.opt.cmdheight = 0
    print '✅ cmdheight=0'
  else
    vim.opt.cmdheight = 1
    print '🚀 cmdheight=1'
  end
end
vim.keymap.set('n', '<leader><leader>c', toggle_cmdheight, { desc = 'Toggle cmdheight' })
-- }}}

-- Get Selection Data {{{
-- 🚀 Extracts the necessary path and line selection data for formatting.
local function get_selection_data()
  -- ℹ️ Retrieves both absolute (with ~) and relative paths.
  local abs_path = vim.fn.expand '%:p:~'
  local rel_path = vim.fn.expand '%:.'

  -- 💡 Validates if the relative path is empty (e.g., an unsaved buffer) and defaults to the absolute path.
  if rel_path == '' then rel_path = abs_path end

  local mode = vim.api.nvim_get_mode().mode
  local start_line
  local end_line

  if mode:match '[vV\x16]' then
    local v_start = vim.fn.getpos('v')[2]
    local v_end = vim.fn.getpos('.')[2]

    start_line = math.min(v_start, v_end)
    end_line = math.max(v_start, v_end)

    -- ℹ️ Resets visual mode to normal mode safely after extraction.
    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', true)
  else
    start_line = vim.fn.line '.'
    end_line = start_line
  end

  return abs_path, rel_path, start_line, end_line
end

-- 🚀 Creates a specific copy function based on the requested format.
local function create_copy_command(format_type)
  return function()
    local abs_path, rel_path, start_line, end_line = get_selection_data()
    local result = ''

    if format_type == 'oc' then
      result = string.format('%s L%d-L%d', abs_path, start_line, end_line)
    elseif format_type == 'or' then
      result = string.format('%s L%d-L%d', rel_path, start_line, end_line)
    elseif format_type == 'oa' then
      result = abs_path
    elseif format_type == 'oz' then
      result = rel_path
    elseif format_type == 'ol' then
      result = string.format('L%d-L%d', start_line, end_line)
    end

    -- ✅ Copies the computed result to the system clipboard register.
    vim.fn.setreg('+', result)
    vim.notify('Copied: ' .. result, vim.log.levels.INFO)
  end
end

-- 🔥 Maps the respective formatting commands to normal and visual modes.
local copy_mappings = {
  ['<leader>oc'] = { type = 'oc', desc = 'Copy absolute path and lines' },
  ['<leader>or'] = { type = 'or', desc = 'Copy relative path and lines' },
  ['<leader>oa'] = { type = 'oa', desc = 'Copy absolute path only' },
  ['<leader>oz'] = { type = 'oz', desc = 'Copy relative path only' },
  ['<leader>ol'] = { type = 'ol', desc = 'Copy lines only' },
}

for key, opts in pairs(copy_mappings) do
  vim.keymap.set({ 'n', 'x' }, key, create_copy_command(opts.type), {
    noremap = true,
    silent = true,
    desc = opts.desc,
  })
end
-- }}}

-- A single file source code runner for problem solving {{{
local run_commands = {
  c = 'cc -std=c17 -g -O2 -Wall -Wextra -Wshadow -fsanitize=address,undefined %s -o %s -lm && %s',
  cpp = 'c++ -std=c++17 -g -O2 -Wall -Wextra -Wshadow -fsanitize=address,undefined %s -o %s -lm && %s',
  python = 'python3 -u %s',
  rust = 'rustc -g -O %s -o %s && %s',
}

local function open_input_file()
  local input_file = vim.fn.expand '%:p:r' .. '.in'
  vim.cmd('split ' .. vim.fn.fnameescape(input_file))
end

local function run_code()
  if vim.bo.modified then vim.cmd 'write' end

  local ft = vim.bo.filetype
  local cmd_template = run_commands[ft]

  if not cmd_template then
    vim.notify('Unsupported file type: ' .. ft, vim.log.levels.WARN)
    return
  end

  local src = vim.fn.shellescape(vim.fn.expand '%:p')
  local exe = vim.fn.shellescape(vim.fn.expand '%:p:r')
  local input_file = vim.fn.expand '%:p:r' .. '.in'

  local cmd = ''
  if ft == 'python' then
    cmd = string.format(cmd_template, src)
  else
    cmd = string.format(cmd_template, src, exe, exe)
  end

  if vim.fn.filereadable(input_file) == 1 then
    cmd = cmd .. ' < ' .. vim.fn.shellescape(input_file)
  end

  local final_cmd = string.format('%s', cmd)

  vim.cmd 'split'
  vim.cmd('terminal ' .. final_cmd)
  vim.bo.bufhidden = 'wipe'

  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'

  vim.cmd 'startinsert'
end

local function not_supported()
  vim.notify('Code runner not supported for this filetype', vim.log.levels.WARN)
end

vim.keymap.set('n', '<leader>rr', not_supported, { desc = 'Run Code (Disabled)' })
vim.keymap.set('n', '<leader>ri', not_supported, { desc = 'Open Input File (Disabled)' })

local runner_group = vim.api.nvim_create_augroup('UserCodeRunner', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = runner_group,
  pattern = { 'c', 'cpp', 'python', 'rust' },
  callback = function()
    local opts = { buffer = true, silent = true }
    vim.keymap.set(
      'n',
      '<leader>rr',
      run_code,
      vim.tbl_extend('force', opts, { desc = 'Run Code' })
    )
    vim.keymap.set(
      'n',
      '<leader>ri',
      open_input_file,
      vim.tbl_extend('force', opts, { desc = 'Open Input File' })
    )
  end,
})
-- }}}

-- Grep {{{
-- ℹ️ Sets up fallback grep mappings when snacks.nvim is unavailable.
local function setup_fallback_grep()
  local has_snacks, _ = pcall(require, 'snacks')
  if has_snacks then return end

  -- 💡 Creates a reusable asynchronous grep function for both fixed-strings and regex searches.
  local function fallback_grep(is_regex)
    local prompt_str = is_regex and 'Grep (Regex): ' or 'Grep (Fixed): '

    vim.ui.input({ prompt = prompt_str }, function(query)
      if not query or query == '' then return end

      local excludes = {
        '.git',
        'node_modules',
        'dist',
        'build',
        '.next',
        '.cache',
        '.turbo',
        '.vite',
        'coverage',
        'target',
        '__pycache__',
        '.venv',
      }

      local cmd
      local args = {}

      if vim.fn.executable 'rg' == 1 then
        cmd = 'rg'
        args = { '--vimgrep', '--smart-case', '--hidden', '--follow' }

        -- 🚀 Omit any flag for regex, as ripgrep defaults to regex search.
        if not is_regex then table.insert(args, '--fixed-strings') end

        for _, dir in ipairs(excludes) do
          table.insert(args, '-g')
          table.insert(args, '!' .. dir .. '/*')
        end

        -- 💡 Appends '--' to prevent queries starting with '-' from being parsed as flags.
        table.insert(args, '--')
        table.insert(args, query)
      else
        cmd = 'grep'
        args = { '--recursive', '--line-number', '--ignore-case', '-I' }

        if is_regex then
          table.insert(args, '--extended-regexp')
        else
          table.insert(args, '--fixed-strings')
        end

        for _, dir in ipairs(excludes) do
          table.insert(args, '--exclude-dir=' .. dir)
        end

        -- 💡 Appends '--' to prevent queries starting with '-' from being parsed as flags.
        table.insert(args, '--')
        table.insert(args, query)
        table.insert(args, '.')
      end

      -- 🔥 Executes the search asynchronously to prevent UI freezing during extensive operations.
      vim.system({ cmd, unpack(args) }, { text = true }, function(obj)
        vim.schedule(function()
          if obj.code ~= 0 and obj.code ~= 1 then
            vim.notify(
              'Grep command failed with code: ' .. tostring(obj.code),
              vim.log.levels.ERROR
            )
            return
          end

          local lines = vim.split(obj.stdout or '', '\n', { trimempty = true })
          if #lines == 0 then
            vim.notify('No matches found', vim.log.levels.INFO)
            return
          end

          -- ✅ Populates the quickfix list safely in the main Neovim thread.
          vim.fn.setqflist({}, 'r', {
            title = string.format('%s: %s', cmd, query),
            lines = lines,
            efm = cmd == 'rg' and '%f:%l:%c:%m' or '%f:%l:%m',
          })
          vim.cmd 'copen'
        end)
      end)
    end)
  end

  vim.keymap.set(
    'n',
    '<leader>sg',
    function() fallback_grep(false) end,
    { desc = 'Grep to Quickfix (Fixed-strings)' }
  )
  vim.keymap.set(
    'n',
    '<leader>sr',
    function() fallback_grep(true) end,
    { desc = 'Grep to Quickfix (Regex)' }
  )
end

setup_fallback_grep()
-- }}}

-- Find {{{
-- ℹ️ Sets up a fallback file finder mapping with corrected API usage.
local function setup_fallback_find_files()
  local has_snacks, _ = pcall(require, 'snacks')
  if has_snacks then return end

  vim.keymap.set('n', '<leader>ff', function()
    vim.ui.input({ prompt = 'Find File: ' }, function(query)
      if not query or query == '' then return end

      local excludes = {
        '.git',
        'node_modules',
        'dist',
        'build',
        '.next',
        '.cache',
        '.turbo',
        '.vite',
        'coverage',
        'target',
        '__pycache__',
        '.venv',
      }

      local cmd
      local args = {}
      local fd_cmd = vim.fn.executable 'fd' == 1 and 'fd'
        or (vim.fn.executable 'fdfind' == 1 and 'fdfind' or nil)

      if fd_cmd then
        cmd = fd_cmd
        args = { '--type', 'f', '--hidden', '--ignore-case' }
        for _, dir in ipairs(excludes) do
          table.insert(args, '-E')
          table.insert(args, dir)
        end
        table.insert(args, '--')
        table.insert(args, query)
      else
        cmd = 'find'
        args = { '.', '-type', 'f' }
        for _, dir in ipairs(excludes) do
          table.insert(args, '-not', '-path', '*/' .. dir .. '/*')
        end
        table.insert(args, '-iname', '*' .. query .. '*')
      end

      vim.system({ cmd, unpack(args) }, { text = true }, function(obj)
        vim.schedule(function()
          if obj.code ~= 0 and obj.code ~= 1 then
            vim.notify('Find command failed', vim.log.levels.ERROR)
            return
          end

          local lines = vim.split(obj.stdout or '', '\n', { trimempty = true })
          if #lines == 0 then
            vim.notify('No files found', vim.log.levels.INFO)
            return
          end

          -- 🚀 Corrected API call: Pass an empty list as the first argument
          -- and provide all data within the 'what' dictionary (third argument).
          vim.fn.setqflist({}, 'r', {
            title = string.format('Find File: %s', query),
            lines = lines,
          })
          vim.cmd 'copen'
        end)
      end)
    end)
  end, { desc = 'Find Files to Quickfix (Fallback)' })
end

setup_fallback_find_files()
-- }}}

-- Toggle Quickfix and Location list {{{
-- ℹ️ Toggles the quickfix or location list window with strict scope validation.
local function toggle_list(is_loclist)
  local is_open = false

  if is_loclist then
    -- 💡 Location List: strictly scoped to the current window.
    -- Retrieves the window ID of the location list attached to the current window (0).
    local loc_info = vim.fn.getloclist(0, { winid = 0 })
    if loc_info.winid ~= 0 then is_open = true end
  else
    -- 💡 Quickfix: scoped to the current tabpage.
    local current_tab = vim.fn.tabpagenr()
    for _, win in ipairs(vim.fn.getwininfo()) do
      if win.quickfix == 1 and win.loclist == 0 and win.tabnr == current_tab then
        is_open = true
        break
      end
    end
  end

  if is_open then
    -- ✅ Closes the window if it is currently open in the correct scope.
    vim.cmd(is_loclist and 'lclose' or 'cclose')
  else
    -- 🚀 Validates if the list has items before attempting to open it.
    local is_empty = is_loclist and vim.tbl_isempty(vim.fn.getloclist(0))
      or vim.tbl_isempty(vim.fn.getqflist())

    if is_empty then
      local list_name = is_loclist and 'Location' or 'Quickfix'
      vim.notify(list_name .. ' list is empty', vim.log.levels.WARN)
      return
    end

    vim.cmd(is_loclist and 'lopen' or 'copen')
  end
end

-- 🔥 Maps the scope-aware toggle functions to normal mode.
vim.keymap.set(
  'n',
  '<leader>qf',
  function() toggle_list(false) end,
  { desc = 'Toggle Quickfix Window' }
)
vim.keymap.set(
  'n',
  '<leader>ll',
  function() toggle_list(true) end,
  { desc = 'Toggle Location List Window' }
)
-- }}}

-- Netrw {{{
local is_explorer_installed = pcall(require, 'oil') or pcall(require, 'snacks')

if is_explorer_installed then
  -- ❌ Disables the built-in netrw plugin entirely to prevent module conflicts.
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1
else
  -- ℹ️ Recommended optimal settings for netrw.
  vim.g.netrw_banner = 0
  vim.g.netrw_liststyle = 3
  vim.g.netrw_browse_split = 4
  vim.g.netrw_altv = 1
  vim.g.netrw_winsize = 100
  vim.g.netrw_keepdir = 0

  -- 💡 Toggles netrw using explicit Window ID tracking.
  local function toggle_netrw(is_current_file)
    -- 🚀 Closes the window if the tracked Window ID exists and is still valid.
    if vim.t.netrw_win and vim.api.nvim_win_is_valid(vim.t.netrw_win) then
      vim.api.nvim_win_close(vim.t.netrw_win, true)
      vim.t.netrw_win = nil
      return
    end

    local target_dir = vim.fn.getcwd()
    if is_current_file then
      local current_file = vim.fn.expand '%:p'
      if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
        target_dir = vim.fn.expand '%:p:h'
      end
    end

    -- 🔥 Opens netrw in a vertically split window aligned to the left.
    vim.cmd('topleft vsplit ' .. vim.fn.fnameescape(target_dir))
    vim.cmd('vertical resize ' .. vim.g.netrw_winsize)

    -- ✅ Captures and stores the exact Window ID to the current tabpage for robust toggling.
    vim.t.netrw_win = vim.api.nvim_get_current_win()
  end

  vim.keymap.set(
    'n',
    '<leader>ec',
    function() toggle_netrw(false) end,
    { desc = 'Toggle netrw (CWD)' }
  )
  vim.keymap.set(
    'n',
    '<leader>ef',
    function() toggle_netrw(true) end,
    { desc = 'Toggle netrw (Current File)' }
  )
end
-- }}}
-- }}}
