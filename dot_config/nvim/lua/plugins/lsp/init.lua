--[[
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--]]
local set_keymap = vim.keymap.set

local function telescope(cmd)
  return [[<Cmd>lua require("telescope.builtin").]] .. cmd .. [[()<CR>]]
end

local function on_attach(client, bufnr)
  if client.name == "denols" then
    -- asynchronous cache
    vim.system({ "deno", "cache", vim.api.nvim_buf_get_name(bufnr) }, {}, function() end)
  end
  require("lsp_signature").on_attach({ hint_enable = false, handler_opts = { border = "none" } }, bufnr)
  set_keymap("i", "<C-G><C-H>", require("lsp_signature").toggle_float_win, { buffer = bufnr })

  -- Enable completion triggered by <c-x><c-o>
  vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local opts = { silent = true, buffer = bufnr }
  set_keymap("n", "gD", [[<Cmd>lua vim.lsp.buf.declaration()<CR>]], opts)
  set_keymap("n", "gd", telescope("lsp_definitions"), opts)
  if client.server_capabilities.implementationProvider then
    set_keymap("n", "gf", [[<Cmd>lua require("plugins.telescope.picker").gti()<CR>]], opts)
  else
    set_keymap("n", "gf", [[<Cmd>lua require("plugins.telescope.picker").gtd()<CR>]], opts)
  end
  -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
  set_keymap("n", "gi", telescope("lsp_implementations"), opts)
  -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
  set_keymap("n", "gr", telescope("lsp_references"), opts)
  -- set_keymap('n', 'gr', vim.lsp.buf.references, OPTS)
  set_keymap("n", "<C-K>", [[<Cmd>lua vim.lsp.buf.signature_help()<CR>]], opts)
  set_keymap("n", " lt", [[<Cmd>lua vim.lsp.buf.type_definition()<CR>]], opts)
  if client.server_capabilities.renameProvider then
    set_keymap("n", " r", [[<Cmd>lua vim.lsp.buf.rename()<CR>]], opts)
  end
  -- set_keymap("n", " la", [[<Cmd>lua vim.lsp.buf.code_action()<CR>]], opts)
  set_keymap("n", " la", [[<Cmd>lua require('lspsaga.codeaction'):code_action()<CR>]], opts)
end

local function lspconfig()
  require("ddc_source_lsp_setup").setup()
  local function config(nm, opts)
    require("lspconfig")[nm].setup(opts)
  end
  config("clangd", {})
  -- config("ruff_lsp", {}) -- dot_config/ruff/ruff.toml (too lazy to filter similar diagnostics from pyright...)
  config("pyright", { -- https://github.com/microsoft/pyright/blob/main/docs/configuration.md
    settings = {
      python = {
        venvPath = ".",
        pythonPath = "./.venv/bin/python",
        analysis = {
          extraPaths = { "." },
        },
        exclude = { "./.worktree" },
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
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim", "pandoc" } },
        workspace = {
          library = { vim.env.VIMRUNTIME }, -- NOTE: vim.api.nvim_get_runtime_file("", true) can be too heavy
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
    "https://github.com/neovim/nvim-lspconfig",
    dependencies = {
      "https://github.com/williamboman/mason.nvim",
      "https://github.com/williamboman/mason-lspconfig.nvim",
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      vim.lsp.set_log_level(vim.lsp.log_levels.OFF)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("atusy.nvim-lspconfig", {}),
        callback = function(ctx)
          local client = vim.lsp.get_client_by_id(ctx.data.client_id)
          on_attach(client, ctx.buf)
        end,
      })
      lspconfig()
      vim.diagnostic.config({ signs = false })
    end,
  },
  { "https://github.com/uga-rosa/ddc-source-lsp-setup", lazy = true },
  {
    "https://github.com/ray-x/lsp_signature.nvim", -- or { "https://github.com/matsui54/denops-signature_help" }
    lazy = true,
    -- configured via on_attach
  },
  {
    "https://github.com/williamboman/mason.nvim",
    lazy = true,
    cmd = { "Mason" },
    config = function()
      require("mason").setup()
    end,
  },
  {
    "https://github.com/williamboman/mason-lspconfig.nvim",
    lazy = true,
    dependencies = { "https://github.com/williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup()
    end,
  },
  {
    "https://github.com/j-hui/fidget.nvim",
    event = "LspAttach",
    config = function()
      require("fidget").setup()
    end,
  },
  {
    "https://github.com/nvimdev/lspsaga.nvim",
    lazy = true,
    init = function()
      vim.keymap.set("n", "[d", function()
        require("lspsaga.diagnostic"):goto_prev({
          severity = require("atusy.diagnostic").underlined_severities(),
        })
      end)
      vim.keymap.set("n", "]d", function()
        require("lspsaga.diagnostic"):goto_next({
          severity = require("atusy.diagnostic").underlined_severities(),
        })
      end)
      vim.keymap.set("n", " e", function()
        -- focus to the current menu
        local winid = require("lspsaga.diagnostic").winid
        if winid then
          vim.api.nvim_set_current_win(winid)
          return
        end

        -- focus or show
        -- TODO: on <CR>, let's open and focus to lspsaga.diagnostic.winid
        local args = {}
        if not require("lspsaga.diagnostic.show").winid then
          table.insert(args, "++unfocus")
        end
        require("lspsaga.diagnostic.show"):show_diagnostics({ line = true, args = args })
      end)
    end,
    config = function()
      require("lspsaga").setup({
        lightbulb = { enable = false },
        symbol_in_winbar = { enable = false },
      })
    end,
  },
}
