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
				views = {
					finder = {
						close_on_select = false,
						confirm_simple = true,
						follow_current_file = false,
						mappings = require("plugins.fyler.mappings"),
					},
				},
			})
		end,
	},
}
