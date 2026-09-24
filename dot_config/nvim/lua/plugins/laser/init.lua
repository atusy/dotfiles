return {
	-- Word list consumed by tsudoi-language-server.
	{ "https://github.com/dwyl/english-words", lazy = true },
	{
		"https://github.com/atusy/laser.nvim",
		dev = true,
		config = function()
			require("plugins.laser.completion").setup()
		end,
	},
}
