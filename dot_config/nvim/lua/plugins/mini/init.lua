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
			vim.keymap.set({ "x", "n" }, "s", "<cmd>lua require('plugins.mini.surround')()<cr>s", { remap = true })
		end,
	},
}
