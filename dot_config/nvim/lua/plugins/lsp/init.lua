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
				group = vim.api.nvim_create_augroup("atusy.lsp_signature", {}),
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
}
