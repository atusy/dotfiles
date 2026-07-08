return {
	{
		"https://github.com/A7Lavinraj/fyler.nvim",
		init = function()
			vim.keymap.set("n", "S", function()
				require("fyler").open()
			end)
		end,
		config = function()
			require("fyler").setup({
				auto_confirm_simple_mutation = true,
				follow_current_file = false,
				kind_presets = {
					replace = {
						mappings = require("plugins.fyler.mappings"),
					},
				},
			})
		end,
	},
}
