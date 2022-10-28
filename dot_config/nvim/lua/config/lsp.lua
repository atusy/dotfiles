local vim = vim

local utils = require('utils')
local set_keymap = utils.set_keymap

local function attach(filetype)
  filetype = filetype or vim.api.nvim_buf_get_option(0, "filetype")
  local clients = {}
  for _, cl in ipairs(vim.lsp.get_active_clients()) do
    if cl.config and cl.config.filetypes then
      for _, ft in ipairs(cl.config.filetypes) do
        if ft == filetype then
          vim.lsp.buf_attach_client(0, cl.id)
          table.insert(clients, cl)
        end
      end
    end
  end
  return clients
end

local create_autocmd = function()
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
      attach(filetype)
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

local function hover(default)
  if utils.has_lsp_client(0) then
    vim.lsp.buf.hover()
  else
    vim.cmd(default or "normal! K")
  end
end

local function setup(_)
  -- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
  create_autocmd()
  vim.fn['signature_help#enable']()
  require("mason").setup()
  local LspSaga = require 'lspsaga'
  LspSaga.init_lsp_saga({
    code_action_lightbulb = { virtual_text = false, sign = false }
  })
  set_keymap('n', '<Leader>e', vim.diagnostic.open_float, { silent = true, desc = 'float diagnostic' })
  set_keymap('n', '[d', vim.diagnostic.goto_prev, { silent = true, desc = 'previous diagnostic' })
  set_keymap('n', ']d', vim.diagnostic.goto_next, { silent = true, desc = 'next diagnositc' })
  set_keymap('n', '<Leader>q', vim.diagnostic.setloclist,
    { silent = true, desc = 'add buffer diagnositcs to the location list' })
  set_keymap('n', 'K', function() hover() end)

  -- Use an on_attach function to only map the following keys
  -- after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local OPTS = { silent = true, buffer = bufnr }
    local TelescopeBuiltin = require('telescope.builtin')
    set_keymap('n', 'gD', vim.lsp.buf.declaration, OPTS)
    set_keymap('n', 'gd', TelescopeBuiltin.lsp_definitions, OPTS)
    -- set_keymap('n', 'gd', vim.lsp.buf.definition, OPTS)
    set_keymap('n', 'gi', TelescopeBuiltin.lsp_implementations, OPTS)
    -- set_keymap('n', 'gi', vim.lsp.buf.implementation, OPTS)
    set_keymap('n', '<C-K>', vim.lsp.buf.signature_help, OPTS)
    set_keymap('n', '<Leader>wa', vim.lsp.buf.add_workspace_folder, OPTS)
    set_keymap('n', '<Leader>wr', vim.lsp.buf.remove_workspace_folder, OPTS)
    set_keymap('n', '<Leader>wl', '<Cmd>print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', OPTS)
    set_keymap('n', '<Leader>D', vim.lsp.buf.type_definition, OPTS)
    -- set_keymap('n', '<Leader>rn', require'lspsaga.rename'.lsp_rename, OPTS)
    set_keymap('n', '<Leader>rn', vim.lsp.buf.rename, OPTS)
    set_keymap('n', '<Leader>ca', require 'lspsaga.codeaction'.code_action, OPTS)
    -- set_keymap('n', '<Leader>ca', vim.lsp.buf.code_action, OPTS)
    set_keymap('n', 'gr', TelescopeBuiltin.lsp_references, { silent = true, buffer = bufnr, desc = 'lsp reference' })
    -- set_keymap('n', 'gr', vim.lsp.buf.references, OPTS)
    set_keymap('n', '<Leader>lf', function() vim.lsp.buf.format({ async = true }) end, OPTS)
  end

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

  -- null_ls
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

return {
  deps = {
    { 'nvim-telescope/telescope.nvim' },
    { 'neovim/nvim-lspconfig' },
    { 'glepnir/lspsaga.nvim' },
    { 'williamboman/mason.nvim' },
    { 'tamago324/nlsp-settings.nvim' },
    { 'ii14/emmylua-nvim' },
    { 'jose-elias-alvarez/null-ls.nvim' },
    { 'matsui54/denops-signature_help' },
  },
  setup = setup
}
