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
			require("plugins.mini.ai").lazy()

			-- lazy load mini.surround
			vim.keymap.set({ "x", "n" }, "s", function()
				vim.keymap.set({ "x", "n" }, "s", "<plug>(s)")
				vim.keymap.set({ "x", "n" }, "<plug>s", "<npp>")
				require("plugins.mini.surround")()
				return "<plug>(s)"
			end, { remap = true, expr = true })

			-- lazy load mini.statusline
			vim.opt.laststatus = 0
			vim.api.nvim_create_autocmd("WinNew", {
				group = vim.api.nvim_create_augroup("atusy.lualine", {}),
				callback = function()
					local cnt = 0
					for _, w in pairs(vim.api.nvim_list_wins()) do
						if vim.api.nvim_win_get_config(w).relative == "" then
							cnt = cnt + 1
							if cnt == 2 then
								break
							end
						end
					end
					if cnt < 2 then
						return
					end

					vim.opt.laststatus = 2
					require("plugins.mini.statusline")()
				end,
			})
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
