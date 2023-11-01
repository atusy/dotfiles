--[[
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--]]
local utils = require("atusy.utils")
local set_keymap = vim.keymap.set

local function telescope(cmd)
  return function()
    require("telescope.builtin")[cmd]()
  end
end
local function on_attach(client, bufnr)
  require("lsp_signature").on_attach({ hint_enable = false, handler_opts = { border = "none" } }, bufnr)
  set_keymap("i", "<C-G><C-H>", require("lsp_signature").toggle_float_win, { buffer = bufnr })

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", { buf = bufnr })

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local function opts(o)
    vim.tbl_extend("keep", o, { silent = true, buffer = bufnr })
  end
  set_keymap("n", "gD", vim.lsp.buf.declaration, opts({ desc = "lsp declaration" }))
  set_keymap("n", "gd", telescope("lsp_definitions"), opts({ desc = "lsp definitions" }))
  -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
  set_keymap("n", "gi", telescope("lsp_implementations"), opts({ desc = "lsp implementation" }))
  -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
  set_keymap("n", "gr", telescope("lsp_references"), opts({ desc = "lsp reference" }))
  -- set_keymap('n', 'gr', vim.lsp.buf.references, OPTS)
  set_keymap("n", "<C-K>", vim.lsp.buf.signature_help, opts({ desc = "lsp show signature help" }))
  set_keymap("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, opts({ desc = "lsp add workspace folder" }))
  set_keymap("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, opts({ desc = "lsp remove workspace folder" }))
  set_keymap("n", "<Leader>D", vim.lsp.buf.type_definition, opts({ desc = "lsp type definition" }))
  if client.server_capabilities.renameProvider then
    set_keymap("n", "<Leader>rn", vim.lsp.buf.rename, opts({ desc = "lsp rename" }))
  end
  set_keymap("n", "<Leader>ca", vim.lsp.buf.code_action, opts({ desc = "lsp code action" }))
  set_keymap("n", "<Leader>lf", function()
    vim.lsp.buf.format({ async = true })
  end, opts({ desc = "lsp format" }))
end

local function lspconfig()
  local capabilities = require("ddc_nvim_lsp").make_client_capabilities()
  local function config(nm, opts)
    opts.capabilities = capabilities
    require("lspconfig")[nm].setup(opts)
  end
  config("clangd", {})
  config("pyright", {
    settings = {
      python = {
        venvPath = ".",
        pythonPath = "./.venv/bin/python",
        analysis = {
          extraPaths = { "." },
        },
      },
    },
  }) -- pip install --user pyright
  config("r_language_server", {}) -- R -e "remotes::install_github('languageserver')"
  config("volar", {})
  local is_node = require("lspconfig").util.find_node_modules_ancestor(".")
  if is_node then
    config("tsserver", {})
  else
    config("denols", {
      single_file_support = true,
    })
  end
  config("gopls", {})
  config("bashls", { filetypes = { "sh", "bash", "zsh" } })
  config("svelte", {})
  config("terraformls", { filetypes = { "terraform", "tf" } })
  config("lua_ls", {
    settings = {
      single_file_support = true,
      Lua = {
        runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
        diagnostics = {
          globals = { "vim", "pandoc" },
        },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        completion = { workspaceWord = true, callSnippet = "Both" },
        format = {
          enable = false,
          defaultConfig = {
            indent_style = "space",
            indent_size = "2",
            continuation_indent_size = "2",
          },
        },
      },
    },
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "jose-elias-alvarez/null-ls.nvim",
      -- "ii14/emmylua-nvim",
      -- "folke/neodev.nvim",
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = utils.augroup,
        callback = function(ctx)
          local client = vim.lsp.get_client_by_id(ctx.data.client_id)
          on_attach(client, ctx.buf)
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        group = utils.augroup,
        callback = function(args)
          require("plugins.lsp.utils").attach_lsp(args.buf, args.match)
        end,
      })
      local init_hover = true
      set_keymap("n", "K", function()
        if init_hover then
          init_hover = false
          vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            max_width = 80,
          })
        end
        -- null-ls won't map this on_attach, so it should be mapped globally
        if #vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }) > 0 then
          vim.lsp.buf.hover()
        else
          vim.cmd("normal! K")
        end
      end)
      lspconfig()
    end,
  },
  {
    "ray-x/lsp_signature.nvim", -- or { "matsui54/denops-signature_help" }
    lazy = true,
    -- configured via on_attach
  },
  {
    "jose-elias-alvarez/null-ls.nvim",
    lazy = true,
    config = function()
      local null_ls = require("null-ls")

      local gitshow = {
        name = "git-show",
        method = null_ls.methods.HOVER,
        filetypes = { "gintonic-graph", "gitrebase" },
        generator = {
          fn = function(_)
            local gintonic = require("gintonic")
            local obj = gintonic.utils.object_getters.default()
            local stdout = vim.system("git show " .. obj .. " --name-status"):wait().stdout
            return vim.fn.split(stdout or "", "\n")
          end,
        },
      }

      null_ls.setup({
        sources = {
          gitshow,
          null_ls.builtins.formatting.stylua,
        },
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    lazy = true,
    cmd = { "Mason" },
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup()
    end,
  },
  {
    "j-hui/fidget.nvim",
    event = "LspAttach",
    branch = "legacy",
    config = function()
      require("fidget").setup()
    end,
  },
  {
    "folke/neodev.nvim",
    lazy = true,
    config = function()
      require("neodev").setup({ experimental = { pathStrict = true } })
    end,
  },
}
