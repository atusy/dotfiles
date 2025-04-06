return {
	{
		-- mini.ai dependency
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		lazy = true,
	},
	{
		"https://github.com/echasnovski/mini.nvim",
		lazy = true,
		init = function()
			local augroup = vim.api.nvim_create_augroup("atusy-mini-nvim", {})

			-- lazy load mini.ai
			vim.api.nvim_create_autocmd("ModeChanged", {
				group = augroup,
				callback = function()
					require("plugins.mini.ai")()
				end,
			})

			-- lazy load mini.surround
			vim.keymap.set({ "x", "n" }, "s", function()
				vim.keymap.set({ "x", "n" }, "s", "<plug>(s)")
				vim.keymap.set({ "x", "n" }, "<plug>s", "<npp>")
				require("plugins.mini.surround")()
				return "<plug>(s)"
			end, { remap = true, expr = true })
		end,
		config = function()
			-- lazy load bini.bufremove
			require("atusy.keymap.palette").add_item(
				"n",
				"Bdelete",
				[[<Cmd>lua require("mini.bufremove").delete()<CR>]]
			)
			require("atusy.keymap.palette").add_item(
				"n",
				"Bwipeout",
				[[<Cmd>lua require("mini.bufremove").wipeout()<CR>]]
			)
		end,
	},
}
