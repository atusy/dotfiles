return {
	{
		"https://github.com/vim-denops/denops.vim",
		init = function(p)
			local bin, cache = require("plugins.denops.utils").get_deno("1.39.1")
			vim.g["denops#deno"] = bin
			vim.g["denops#deno_dir"] = cache
			require("plugins.denops.utils").cache_plugin(p)
		end,
	},
	{
		"https://github.com/yuki-yano/denops-lazy.nvim",
		lazy = true,
		config = function()
			require("denops-lazy").setup()
		end,
	},
}
