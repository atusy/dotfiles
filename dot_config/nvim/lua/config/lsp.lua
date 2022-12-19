local utils = require('utils')
local set_keymap = utils.set_keymap
local attach_lsp = utils.attach_lsp

local setup_autocmd = function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = '*',
    group = utils.augroup,
    callback = function(args)
      require('config.lsp.utils').attach_lsp(args.match)
    end
  })
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { '*.tf', '*.tfvars', '*.lua' },
    group = utils.augroup,
    callback = function()
      pcall(vim.lsp.buf.format)
    end,
  })
end

local function setup_global_keymaps()
  set_keymap('n', '<Leader>e', vim.diagnostic.open_float, { silent = true, desc = 'float diagnostic' })
  set_keymap('n', '[d', vim.diagnostic.goto_prev, { silent = true, desc = 'previous diagnostic' })
  set_keymap('n', ']d', vim.diagnostic.goto_next, { silent = true, desc = 'next diagnositc' })
  set_keymap('n', '<Leader>q', vim.diagnostic.setloclist,
    { silent = true, desc = 'add buffer diagnositcs to the location list' })
  set_keymap('n', 'K', function()
    -- lspconfig won't map this on_attach, so it should be mapped globally
    if require('config.lsp.utils').has_lsp_client(vim.api.nvim_get_current_buf()) then
      vim.lsp.buf.hover()
    else
      return 'K'
    end
  end, { expr = true })
end

local function setup_null_ls()
  local null_ls = require("null-ls")

  local gitshow = {
    name = "git-show",
    method = null_ls.methods.HOVER,
    filetypes = { "gintonic-graph", "gitrebase" },
    generator = {
      fn = function(_)
        local gintonic = require('gintonic')
        local obj = gintonic.utils.object_getters.default()
        local stdout = vim.fn.system("git show " .. obj .. " --name-status")
        return vim.fn.split(stdout, "\n")
      end,
    },
  }

  null_ls.setup({ sources = { gitshow } })
end

local function _setup_lspsaga(enable)
  if enable == false then return _setup_lspsaga end
  require('lspsaga').init_lsp_saga({
    code_action_lightbulb = { virtual_text = false, sign = false },
    finder_action_keys = {
      open = { 'o', '<CR>' },
      vsplit = 'v',
      split = 's',
      tabe = 't',
      quit = { 'q', '<ESC>' },
    },
  })
end

local on_attach = function(client, bufnr)
  _setup_lspsaga = _setup_lspsaga(false) or function(_) end
  local CAPABILITIES = client.server_capabilities

  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local OPTS = { silent = true, buffer = bufnr }
  local telescope = function(key) return "<Cmd>Telescope " .. key .. "<CR>" end
  set_keymap('n', 'gD', vim.lsp.buf.declaration, OPTS, { desc = 'lsp declaration' })
  set_keymap('n', 'gd', telescope('lsp_definitions'), OPTS, { desc = 'lsp definitions' })
  -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
  set_keymap('n', 'gi', telescope('lsp_implementations'), OPTS, { desc = 'lsp implementation' })
  -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
  set_keymap('n', '<C-K>', vim.lsp.buf.signature_help, OPTS, { desc = 'lsp show signature help' })
  set_keymap('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, OPTS, { desc = 'lsp add workspace folder' })
  set_keymap('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, OPTS, { desc = 'lsp remove workspace folder' })
  set_keymap('n', '<Leader>wl', '<Cmd>vim.pretty_print(vim.lsp.buf.list_workspace_folders())<CR>', OPTS,
    { desc = 'lsp show workspace folders' })
  set_keymap('n', '<Leader>D', vim.lsp.buf.type_definition, OPTS, { desc = 'lsp type definition' })
  -- set_keymap('n', '<Leader>rn', '<cmd>Lspsaga rename<cr>', OPTS)
  if CAPABILITIES.renameProvider then
    set_keymap('n', '<Leader>rn', vim.lsp.buf.rename, OPTS, { desc = 'lsp rename' })
  end
  -- set_keymap({ 'n', 'v' }, '<Leader>ca', '<cmd>Lspsaga code_action<cr>', OPTS, { desc = 'lsp code action' })
  set_keymap('n', '<Leader>ca', vim.lsp.buf.code_action, OPTS, { desc = 'lsp code action' })
  -- set_keymap('n', 'gr', '<cmd>Lspsaga lsp_finder<cr>', OPTS, { desc = 'lsp reference' })
  set_keymap('n', 'gr', telescope('lsp_references'), OPTS, { desc = 'lsp reference' })
  -- set_keymap('n', 'gr', vim.lsp.buf.references, OPTS)
  set_keymap('n', '<Leader>lf', function() vim.lsp.buf.format({ async = true }) end, OPTS, { desc = 'lsp format' })
end

local function setup_nvim_lsp()
  require("mason").setup()
  require("mason-lspconfig").setup()
  local Lspconfig = require 'lspconfig'
  local function setup_lsp(lsp, config)
    local config2 = { on_attach = on_attach, flags = { debounce_text_changes = 150 } }
    for k, v in pairs(config or {}) do
      config2[k] = v
    end
    Lspconfig[lsp].setup(config2)
  end

  for lsp, config in pairs {
    pyright = {}, -- pip install --user pyright
    r_language_server = {}, -- R -e "remotes::install_github('languageserver')"
    denols = {},
    bashls = { filetypes = { 'sh', 'bash', 'zsh' } }, -- npm i -g bash-language-server
    terraformls = { filetypes = { "terraform", "tf" } },
    sumneko_lua = {
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT', path = vim.split(package.path, ';') },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            library = vim.env.NVIM_LUA_LIBRARY == 1 and vim.api.nvim_get_runtime_file('', true),
          },
          telemetry = {
            enable = false
          },
        },
      },
    }, -- pacman -S lua-language-server
    gopls = {},
  } do
    setup_lsp(lsp, config)
  end
end

return {
  deps = {
    { 'nvim-telescope/telescope.nvim' },
    { 'neovim/nvim-lspconfig' },
    { 'glepnir/lspsaga.nvim' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'tamago324/nlsp-settings.nvim' },
    { 'ii14/emmylua-nvim' },
    { 'jose-elias-alvarez/null-ls.nvim' },
    { 'matsui54/denops-signature_help' },
  },
  setup = function(_)
    -- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
    setup_autocmd()
    setup_global_keymaps()
    setup_nvim_lsp()
    setup_null_ls()
    vim.fn['signature_help#enable']()
  end
}
