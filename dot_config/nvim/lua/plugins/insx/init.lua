return {
	{
		"https://github.com/hrsh7th/nvim-insx",
		event = "InsertEnter",
		config = function()
			require("kakehashi.extra.endwise").watch()
			require("insx.preset.standard").setup()
			require("plugins.insx.endwise").setup()
		end,
	},
}
