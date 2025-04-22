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
			-- lazy load mini.bufremove
			local bufremove = [[<Cmd>lua require("mini.bufremove").%s()<CR>]]
			require("atusy.keymap.palette").add_item("n", "Bdelete", bufremove:format("delete"))
			require("atusy.keymap.palette").add_item("n", "Bwipeout", bufremove:format("wipeout"))
		end,
	},
}
