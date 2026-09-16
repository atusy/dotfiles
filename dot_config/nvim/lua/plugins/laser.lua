return {
	{
		"https://github.com/atusy/laser.nvim",
		dev = true,
		dependencies = { "https://github.com/Shougo/pum.vim" },
		config = function()
			require("atusy.laser").setup()
		end,
	},
}
