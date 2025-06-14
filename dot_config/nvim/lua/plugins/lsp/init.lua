--[[
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--]]
local set_keymap = vim.keymap.set

local function telescope(cmd)
	return [[<Cmd>lua require("telescope.builtin").]] .. cmd .. [[()<CR>]]
end

local function on_attach(client, bufnr)
	pcall(require, "dressing")
	if client.name == "denols" then
		-- asynchronous cache
		vim.system({ "deno", "cache", vim.api.nvim_buf_get_name(bufnr) }, {}, function() end)
	end
	if client.name ~= "copilot" and client.name ~= "ts_ls" then
		require("lsp_signature").on_attach({ hint_enable = false, handler_opts = { border = "none" } }, bufnr)
		set_keymap("i", "<C-G><C-H>", require("lsp_signature").toggle_float_win, { buffer = bufnr })
	end

	-- Enable completion triggered by <c-x><c-o>
	vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

	-- Mappings.
	-- See `:help vim.lsp.*` for documentation on any of the below functions
	local nmapped = {}
	for _, m in pairs(vim.api.nvim_buf_get_keymap(0, "n")) do
		nmapped[m.lhs] = true
	end
	local function nmap(lhs, rhs)
		if not nmapped[lhs] then
			vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr })
		end
	end
	nmap("gD", [[<Cmd>lua vim.lsp.buf.declaration()<CR>]])
	nmap("gd", telescope("lsp_definitions"))
	nmap("gi", telescope("lsp_implementations"))
	nmap("gr", telescope("lsp_references"))
	nmap("gs", [[<Cmd>lua vim.lsp.buf.signature_help()<CR>]])
	nmap("gK", [[<Cmd>lua vim.lsp.buf.type_definition()<CR>]]) -- Kata teigi
	nmap("ga", [[<Cmd>lua require('lspsaga.codeaction'):code_action()<CR>]]) -- use :as for original ga
	nmap("gf", [[<Cmd>lua require("plugins.telescope.picker").gtd()<CR>]])
	if client.server_capabilities.renameProvider then
		nmap(" r", [[<Cmd>lua vim.lsp.buf.rename()<CR>]])
	end
end

-- LSP configurations are now loaded from after/lsp/*.lua files

return {
	{
		"https://github.com/neovim/nvim-lspconfig",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "Mason" },
		config = function()
			vim.lsp.set_log_level(vim.lsp.log_levels.OFF)
			vim.diagnostic.config({
				signs = false,
				jump = { severity = { "INFO", "WARN", "ERROR" } },
			})
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("atusy.nvim-lspconfig", {}),
				callback = function(ctx)
					local client = vim.lsp.get_client_by_id(ctx.data.client_id)
					on_attach(client, ctx.buf)
				end,
			})
			require("mason")
			require("mason-lspconfig")
			-- LSP configurations loaded automatically from after/lsp/*.lua
			-- Start LSP servers on FileType events using vim.lsp.start
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("atusy.lsp.start", {}),
				callback = function(ctx)
					local bufnr = ctx.buf
					local filetype = ctx.match

					-- Helper function to check for Node.js project
					local function has_node_modules()
						return vim.fn.isdirectory("node_modules") == 1 or vim.fn.findfile("package.json", ".;") ~= ""
					end

					-- List of available LSP servers
					local servers = {
						"bashls",
						"gopls",
						"jsonls",
						"lua_ls",
						"pyright",
						"r_language_server",
						"nixd",
						"terraformls",
						"yamlls",
						has_node_modules() and "ts_ls" or "denols",
					}

					-- enable them for the next time
					vim.lsp.enable(servers)

					-- Check each server to see if it supports the current filetype
					for _, server_name in ipairs(servers) do
						local config = vim.lsp.config[server_name]
						for _, ft in ipairs(config and config.filetypes or {}) do
							if ft == filetype then
								vim.lsp.start(config, { bufnr = bufnr })
							end
						end
					end

					-- delay to avoid racing conditions on loading multiple buffers at the same time
					vim.schedule(function()
						pcall(vim.api.nvim_del_autocmd, ctx.id)
					end)
				end,
			})
			require("fidget").setup()
		end,
	},
	-- nvim-lspconfig's config loads following plugins except lspsaga
	{ "https://github.com/uga-rosa/ddc-source-lsp-setup", lazy = true },
	{ "https://github.com/ray-x/lsp_signature.nvim", lazy = true },
	{
		"https://github.com/mason-org/mason.nvim",
		lazy = true,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"https://github.com/mason-org/mason-lspconfig.nvim",
		lazy = true,
		config = function()
			require("mason-lspconfig").setup()
		end,
	},
	{ "https://github.com/j-hui/fidget.nvim", lazy = true },
	{ "https://github.com/b0o/SchemaStore.nvim", lazy = true },
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
			vim.keymap.set("n", "<space>d", function()
				-- focus to the current menu
				if require("lspsaga.diagnostic"):valid_win_buf() then
					vim.api.nvim_set_current_win(require("lspsaga.diagnostic").float_winid)
					return
				end

				-- focus or show
				local args = {}
				local winid = require("lspsaga.diagnostic.show").winid
				if not winid or not vim.api.nvim_win_is_valid(winid) then
					table.insert(args, "++unfocus")
				end
				require("lspsaga.diagnostic.show"):show_diagnostics({ cursor = true, args = args })
			end)
		end,
		config = function()
			require("lspsaga").setup({
				lightbulb = { enable = false },
				symbol_in_winbar = { enable = false },
			})
		end,
	},
	{
		"https://github.com/kuuote/lspoints",
		lazy = true,
		config = function()
			require("mason") -- dependency

			local function attach_denols()
				vim.fn["lspoints#attach"]("denols", {
					cmd = { "deno", "lsp" },
					cmdOptions = {
						env = { DENO_DIR = vim.env.DENO_DIR or vim.fs.joinpath(vim.uv.os_homedir(), ".cache", "deno") },
					},
					initializationOptions = {
						enable = true,
						unstable = true,
						suggest = { imports = { hosts = { ["https://deno.land"] = true } } },
					},
				})
			end

			local function attach_luals()
				vim.fn["lspoints#attach"]("luals", {
					cmd = { "lua-language-server" },
					initializationOptions = {
						runtime = { version = "LuaJIT" },
						diagnostics = { globals = { "vim", "pandoc" } },
						workspace = {
							library = { vim.env.VIMRUNTIME }, -- NOTE: vim.api.nvim_get_runtime_file("", true) can be too heavy
							checkThirdParty = false,
						},
						completion = { workspaceWord = false, callSnippet = "Both" },
						format = { enable = true },
					},
				})
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("atusy-lspoints", {}),
				callback = function(ctx)
					-- attach
					local ft = ctx.match
					if ft == "typescript" or ft == "typescriptreact" then
						local function has_node_modules()
							return vim.fn.isdirectory("node_modules") == 1
								or vim.fn.findfile("package.json", ".;") ~= ""
						end
						if has_node_modules() then
							return
						end
						attach_denols()
					elseif ft == "lua" then
						-- attach_luals()
					else
						return
					end

					-- extensions
					vim.fn["lspoints#load_extensions"]({ "nvim_diagnostics", "format" })

					-- mappings
					vim.keymap.set(
						"n",
						" lf",
						"<Cmd>call denops#request('lspoints', 'executeCommand', ['format', 'execute', bufnr()])<CR>",
						{ silent = true, buffer = true }
					)

					-- completions
					-- textDocument/resolve not working well
					vim.fn["ddc#custom#patch_buffer"]({ sourceParams = { lsp = { lspEngine = "lspoints" } } })
				end,
			})
		end,
	},
}
