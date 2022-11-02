local vim = vim

local utils = require('utils')
local set_keymap = utils.set_keymap
local attach_lsp = utils.attach_lsp

local setup_autocmd = function()
  local group = vim.api.nvim_create_augroup("atusy-lsp", {})
  vim.api.nvim_create_autocmd("FileType", {
    pattern = '*',
    group = group,
    callback = function()
      -- modify filetype if needed
      local filetype_table = {
        tf = "terraform"
      }
      local filetype = vim.api.nvim_buf_get_option(0, "filetype")
      if filetype_table[filetype] then
        filetype = filetype_table[filetype]
        vim.api.nvim_buf_set_option(0, "filetype", filetype)
      end

      -- attach lsp if needed
      -- there are some cases e! detaches clients
      attach_lsp(filetype)
    end
  })
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { '*.tf', '*.tfvars', '*.lua' },
    group = group,
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
    if utils.has_lsp_client(0) then
      vim.lsp.buf.hover()
    else
      vim.cmd('normal! K')
    end
  end)
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
        return gintonic.utils.get_lines(
          function() return gintonic.tonic.show(obj, nil, "--name-status") end
        )
      end,
    },
  }

  null_ls.setup({ sources = { gitshow } })
end

local function resolve_capability(client, feature)
  return client and client.server_capabilities and client.server_capabilities[feature] or false
end

local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local OPTS = { silent = true, buffer = bufnr }
  local TelescopeBuiltin = require('telescope.builtin')
  set_keymap('n', 'gD', vim.lsp.buf.declaration, OPTS, { desc = 'lsp declaration' })
  set_keymap('n', 'gd', TelescopeBuiltin.lsp_definitions, OPTS, { desc = 'lsp definitions' })
  -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
  set_keymap('n', 'gi', TelescopeBuiltin.lsp_implementations, OPTS, { desc = 'lsp implementation' })
  -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
  set_keymap('n', '<C-K>', vim.lsp.buf.signature_help, OPTS, { desc = 'lsp show signature help' })
  set_keymap('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, OPTS, { desc = 'lsp add workspace folder' })
  set_keymap('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, OPTS, { desc = 'lsp remove workspace folder' })
  set_keymap('n', '<Leader>wl', '<Cmd>print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', OPTS,
    { desc = 'lsp show workspace folders' })
  set_keymap('n', '<Leader>D', vim.lsp.buf.type_definition, OPTS, { desc = 'lsp type definition' })
  -- set_keymap('n', '<Leader>rn', '<cmd>Lspsaga rename<cr>', OPTS)
  if resolve_capability(client, "renameProvider") then
    set_keymap('n', '<Leader>rn', vim.lsp.buf.rename, OPTS, { desc = 'lsp rename' })
  end
  set_keymap({ 'n', 'v' }, '<Leader>ca', '<cmd>Lspsaga code_action<cr>', OPTS, { desc = 'lsp code action' })
  -- set_keymap('n', '<Leader>ca', vim.lsp.buf.code_action, OPTS)
  set_keymap('n', 'gr', '<cmd>Lspsaga lsp_finder<cr>', OPTS, { desc = 'lsp reference' })
  -- set_keymap('n', 'gr', TelescopeBuiltin.lsp_references, OPTS, { desc = 'lsp reference' })
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
        Lua = vim.env.LUA_RUNTIME and {
          workspace = {
            library = vim.api.nvim_get_runtime_file('', true),
          },
        } or {},
      },
    }, -- pacman -S lua-language-server
    gopls = {},
  } do
    setup_lsp(lsp, config)
  end
end

local function setup_lspsaga()
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
    setup_lspsaga()
    setup_nvim_lsp()
    setup_null_ls()
    vim.fn['signature_help#enable']()
  end
}
