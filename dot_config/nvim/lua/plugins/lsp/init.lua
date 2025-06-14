--[[
https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
--]]
local set_keymap = vim.keymap.set

local function telescope(cmd)
	return [[<Cmd>lua require("telescope.builtin").]] .. cmd .. [[()<CR>]]
end

local function on_attach(client, bufnr)
	-- Mappings.
	local function nmap(lhs, rhs)
		vim.keymap.set("n", lhs, rhs, { silent = true, buffer = bufnr })
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

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("atusy.nvim-lspconfig", {}),
	callback = function(ctx)
		local client = vim.lsp.get_client_by_id(ctx.data.client_id)
		on_attach(client, ctx.buf)
	end,
})

return {
	--[[ LSP configurations ]]
	{ "https://github.com/neovim/nvim-lspconfig", lazy = true }, -- loaded via atusy.lsp
	{ "https://github.com/b0o/SchemaStore.nvim", lazy = true }, -- loaded via after/lsp/*.lua
	--[[ LSP UI ]]
	{
		"https://github.com/ray-x/lsp_signature.nvim",
		lazy = true,
		init = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("atusy.nvim-lspconfig", {}),
				callback = function(ctx)
					local bufnr = ctx.buf
					local client = vim.lsp.get_client_by_id(ctx.data.client_id)
					if not client then
						return
					end
					if client.name == "copilot" or client.name == "ts_ls" then
						return
					end
					require("lsp_signature").on_attach(
						{ hint_enable = false, handler_opts = { border = "none" } },
						bufnr
					)
					vim.keymap.set("i", "<C-G><C-H>", require("lsp_signature").toggle_float_win, { buffer = bufnr })
				end,
			})
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
	--[[ Extra LSP Clients ]]
	{
		"https://github.com/kuuote/lspoints",
		lazy = true,
		config = function()
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
