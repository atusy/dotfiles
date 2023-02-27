local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local function setup_autocmd()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    group = utils.augroup,
    callback = function(args)
      require("plugins.lsp.utils").attach_lsp(args.match)
    end,
  })
end

local function setup_global_keymaps()
  set_keymap("n", "K", function()
    -- null-ls won't map this on_attach, so it should be mapped globally
    if require("plugins.lsp.utils").has_lsp_client() then
      vim.lsp.buf.hover()
    else
      return "K"
    end
  end, { expr = true })
end

local on_attach = function(client, bufnr)
  local CAPABILITIES = client.server_capabilities

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local OPTS = { silent = true, buffer = bufnr }
  local telescope = function(key)
    return "<Cmd>Telescope " .. key .. "<CR>"
  end
  set_keymap("n", "gD", vim.lsp.buf.declaration, OPTS, { desc = "lsp declaration" })
  set_keymap("n", "gd", telescope("lsp_definitions"), OPTS, { desc = "lsp definitions" })
  -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
  set_keymap("n", "gi", telescope("lsp_implementations"), OPTS, { desc = "lsp implementation" })
  -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
  set_keymap("n", "<C-K>", vim.lsp.buf.signature_help, OPTS, { desc = "lsp show signature help" })
  set_keymap("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, OPTS, { desc = "lsp add workspace folder" })
  set_keymap("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, OPTS, { desc = "lsp remove workspace folder" })
  set_keymap(
    "n",
    "<Leader>wl",
    "<Cmd>vim.pretty_print(vim.lsp.buf.list_workspace_folders())<CR>",
    OPTS,
    { desc = "lsp show workspace folders" }
  )
  set_keymap("n", "<Leader>D", vim.lsp.buf.type_definition, OPTS, { desc = "lsp type definition" })
  -- set_keymap('n', '<Leader>rn', '<cmd>Lspsaga rename<cr>', OPTS)
  if CAPABILITIES.renameProvider then
    set_keymap("n", "<Leader>rn", vim.lsp.buf.rename, OPTS, { desc = "lsp rename" })
  end
  -- set_keymap({ 'n', 'x' }, '<Leader>ca', '<cmd>Lspsaga code_action<cr>', OPTS, { desc = 'lsp code action' })
  set_keymap("n", "<Leader>ca", vim.lsp.buf.code_action, OPTS, { desc = "lsp code action" })
  -- set_keymap('n', 'gr', '<cmd>Lspsaga lsp_finder<cr>', OPTS, { desc = 'lsp reference' })
  set_keymap("n", "gr", telescope("lsp_references"), OPTS, { desc = "lsp reference" })
  -- set_keymap('n', 'gr', vim.lsp.buf.references, OPTS)
  set_keymap("n", "<Leader>lf", function()
    vim.lsp.buf.format({ async = true })
  end, OPTS, { desc = "lsp format" })
end

local function setup_nvim_lsp()
  local Lspconfig = require("lspconfig")
  local function setup_lsp(lsp, config)
    local config2 = { on_attach = on_attach, flags = { debounce_text_changes = 150 } }
    for k, v in pairs(config or {}) do
      config2[k] = v
    end
    Lspconfig[lsp].setup(config2)
  end

  for lsp, config in pairs({
    pyright = {}, -- pip install --user pyright
    r_language_server = {}, -- R -e "remotes::install_github('languageserver')"
    denols = {},
    bashls = { filetypes = { "sh", "bash", "zsh" } }, -- npm i -g bash-language-server
    terraformls = { filetypes = { "terraform", "tf" } },
    lua_ls = {
      settings = {
        single_file_support = true,
        Lua = {
          -- runtime and workspace.library are required to suppress vim being undefined global
          runtime = { version = "LuaJIT", path = vim.split(package.path, ";") },
          diagnostics = {
            globals = { "vim", "pandoc" },
          },
          workspace = {
            library = vim.env.NVIM_LUA_LIBRARY == 1 and vim.api.nvim_get_runtime_file("", true),
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
          -- telemetry = { enable = false },
        },
      },
    }, -- pacman -S lua-language-server
    gopls = {},
  }) do
    setup_lsp(lsp, config)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "jose-elias-alvarez/null-ls.nvim" },
      { "matsui54/denops-signature_help" },
      { "ii14/emmylua-nvim" },
      { "tamago324/nlsp-settings.nvim" },
      { "folke/neodev.nvim" },
      { "j-hui/fidget.nvim" },
      -- { 'glepnir/lspsaga.nvim' },
    },
    config = function()
      setup_autocmd()
      setup_global_keymaps()
      setup_nvim_lsp()
    end,
  },
  {
    "glepnir/lspsaga.nvim",
    enabled = false,
    event = "BufRead",
    config = function()
      require("lspsaga").setup({})
    end,
    dependencies = {
      { "nvim-tree/nvim-web-devicons" },
      { "nvim-treesitter/nvim-treesitter" }, -- needs markdown and markdown_inline parser
    },
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
            local stdout = vim.fn.system("git show " .. obj .. " --name-status")
            return vim.fn.split(stdout, "\n")
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
    "matsui54/denops-signature_help",
    lazy = true,
    config = function()
      vim.fn["signature_help#enable"]()
    end,
  },
  {
    "j-hui/fidget.nvim",
    lazy = true,
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
  {
    "zbirenbaum/neodim",
    event = "LspAttach",
    config = function()
      require("neodim").setup({
        alpha = 0.75,
        blend_color = "#000000",
        update_in_insert = {
          enable = true,
          delay = 100,
        },
        hide = {
          virtual_text = true,
          signs = true,
          underline = true,
        },
      })
    end,
  },
}
