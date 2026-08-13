vim.opt.runtimepath:prepend(assert(vim.env.MINI_TEST_PATH, "MINI_TEST_PATH is required"))
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/dot_config/nvim")

require("mini.test").setup({
	collect = {
		find_files = function()
			return vim.fn.globpath("dot_config/nvim/tests", "test_*.lua", true, true)
		end,
	},
})
