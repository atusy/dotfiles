local vim = vim

local utils = require('utils')
local set_keymap = utils.set_keymap
local has_lsp_client = utils.has_lsp_client

local function hover(bufnr, default)
  if has_lsp_client(bufnr or vim.api.nvim_get_current_buf()) then
    return vim.lsp.buf.hover()
  end
  return vim.cmd(default or "normal! K")
end

local function setup(_)
  -- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
  require("mason").setup()
  local LspSaga = require'lspsaga'
  LspSaga.init_lsp_saga({
    code_action_lightbulb = { virtual_text = false, sign = false }
  })
  set_keymap('n', '<Leader>e', vim.diagnostic.open_float, {silent = true, desc = 'float diagnostic'})
  set_keymap('n', '[d', vim.diagnostic.goto_prev, {silent = true, desc = 'previous diagnostic'})
  set_keymap('n', ']d', vim.diagnostic.goto_next, {silent = true, desc = 'next diagnositc'})
  set_keymap('n', '<Leader>q', vim.diagnostic.setloclist, {silent = true, desc = 'add buffer diagnositcs to the location list'})
  set_keymap('n', 'K', function() hover() end)

  -- Use an on_attach function to only map the following keys
  -- after the language server attaches to the current buffer
  local on_attach = function(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local OPTS = {silent = true, buffer = bufnr}
    local TelescopeBuiltin = require('telescope.builtin')
    set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', OPTS)
    set_keymap('n', 'gd', TelescopeBuiltin.lsp_definitions, OPTS)
    -- set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', OPTS)
    set_keymap('n', 'gi', TelescopeBuiltin.lsp_implementations, OPTS)
    -- set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', OPTS)
    set_keymap('n', '<C-K>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', OPTS)
    set_keymap('n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', OPTS)
    set_keymap('n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', OPTS)
    set_keymap('n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', OPTS)
    set_keymap('n', '<Leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', OPTS)
    -- set_keymap('n', '<Leader>rn', require'lspsaga.rename'.lsp_rename, OPTS)
    set_keymap('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', OPTS)
    set_keymap('n', '<Leader>ca', require'lspsaga.codeaction'.code_action, OPTS)
    -- set_keymap('n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', OPTS)
    set_keymap('n', 'gr', TelescopeBuiltin.lsp_references, {silent = true, buffer = bufnr, desc = 'lsp reference'})
    -- set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', OPTS)
    set_keymap('n', '<Leader>lf', '<cmd>lua vim.lsp.buf.formatting()<CR>', OPTS)
  end

  local Lspconfig = require'lspconfig'
  local function setup_lsp(lsp, config)
    local config2 = {on_attach = on_attach, flags = {debounce_text_changes = 150}}
    for k, v in pairs(config or {}) do
      config2[k] = v
    end
    Lspconfig[lsp].setup(config2)
  end

  for lsp, config in pairs{
    pyright = {}, -- pip install --user pyright
    r_language_server = {}, -- R -e "remotes::install_github('languageserver')"
    denols = {},
    bashls = {filetypes = {'sh', 'bash', 'zsh'}}, -- npm i -g bash-language-server
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

  vim.api.nvim_create_augroup("terraform-custom", {})
  vim.api.nvim_create_autocmd({"FileType"}, {
    group="terraform-custom",
    pattern = { "tf" },
    callback = function(_)
      vim.api.nvim_buf_set_option(0, "filetype", "terraform")
    end
  })
  vim.api.nvim_create_autocmd({"BufWritePre"}, {
    group="terraform-custom",
    pattern = {"*.tf", "*.tfvars"},
    callback = vim.lsp.buf.formatting_sync,
  })

  -- null_ls
  local null_ls = require("null-ls")
  null_ls.reset_sources()
  null_ls.setup()

  null_ls.register({
    name = "git-show",
    method = null_ls.methods.HOVER,
    filetypes = { "gintonic-graph", "gitrebase" },
    generator = {
      fn = function(_)
        local gintonic = require('gintonic')
        local obj = gintonic.utils.object_getters.default()
        return gintonic.utils.get_lines(
          function() return gintonic.tonic.show(obj, nil, "--no-patch") end
        )
      end,
    },
  })
end

return {
  deps = {
    {'nvim-telescope/telescope.nvim'},
    {'neovim/nvim-lspconfig'},
    {'glepnir/lspsaga.nvim'},
    {'williamboman/mason.nvim'},
    {'tamago324/nlsp-settings.nvim'},
    {'ii14/emmylua-nvim'},
    {'jose-elias-alvarez/null-ls.nvim'},
  },
  setup = setup
}
