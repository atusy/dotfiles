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
			require("plugins.mini.surround").lazy()
			require("plugins.mini.statusline").lazy()
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
