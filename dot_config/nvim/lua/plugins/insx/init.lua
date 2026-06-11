return {
	{
		"https://github.com/hrsh7th/nvim-insx",
		event = "InsertEnter",
		config = function()
			require("insx.preset.standard").setup()
			require("plugins.insx.endwise").setup()
		end,
	},
}
