return {
	{
		"https://github.com/hrsh7th/nvim-insx",
		event = "InsertEnter",
		config = function()
			require("insx.preset.standard").setup()
			require("plugins.insx.endwise").setup()
		end,
	},
	{
		-- to provide query files
		"https://github.com/RRethy/nvim-treesitter-endwise",
		init = function()
			-- avoid unconditional run of require("nvim-treesitter-endwise").init() on source,
			-- which sets a global <CR> on_key handler
			package.loaded["nvim-treesitter-endwise"] = { init = function() end }
		end,
	},
}
