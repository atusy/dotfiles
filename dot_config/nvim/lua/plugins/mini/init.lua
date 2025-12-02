return {
	{
		-- mini.ai dependency
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		lazy = true,
	},
	{
		"https://github.com/nvim-mini/mini.nvim",
		lazy = true,
		init = function()
			require("plugins.mini.ai").lazy()
			require("plugins.mini.surround").lazy()
			require("plugins.mini.statusline").lazy()
			require("plugins.mini.indentscope").lazy()
			vim.keymap.set("n", "ZR", function()
				if vim.v.count > 0 then
					vim.cmd("restart")
					return
				end
				require("mini.sessions").setup()
				require("mini.sessions").write("ZR")
				vim.cmd(
					[[restart lua (function() require("mini.sessions").setup(); require("mini.sessions").read("ZR") end)()]]
				)
			end)
		end,
		config = function()
			-- lazy load mini.bufremove
			local bufremove = [[<Cmd>lua require("mini.bufremove").%s()<CR>]]
			require("atusy.keymap.palette").add_item("n", "Bdelete", bufremove:format("delete"))
			require("atusy.keymap.palette").add_item("n", "Bwipeout", bufremove:format("wipeout"))
		end,
	},
}
