return {
	{
		"https://github.com/vim-denops/denops.vim",
		init = function(p)
			local bin, cache = require("plugins.denops.utils").get_deno("2.0.2")
			vim.g["denops#deno"] = bin
			vim.g["denops#deno_dir"] = cache
			vim.g["denops#server#deno_args"] = { "-q", "--no-lock", "-A", "--unstable-kv" }
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
