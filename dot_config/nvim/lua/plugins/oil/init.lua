local L = {}

function L.cb(opts)
	vim.keymap.set("n", "#", function()
		local cdir = vim.fs.dirname(opts.cfile)
		if vim.uv.fs_stat(opts.cfile) then
			L.open({ dir = cdir, cfile = opts.cfile })
		end
	end, { buffer = true })
	vim.keymap.set("n", "<c-s>", function()
		require("oil").save()
	end, { buffer = true })
	vim.keymap.set("n", "<cr>", function()
		require("oil").select(nil, function()
			L.cb(opts)
		end)
	end, { buffer = true })
end

function L.open(opts)
	require("oil").open(opts.dir or ".", nil, function()
		L.cb(opts)
	end)
end

return {
	{
		"https://github.com/stevearc/oil.nvim",
		lazy = true,
		init = function() end,
		config = function()
			require("oil").setup({
				keymaps = {
					["<C-s>"] = false,
					["<C-t>"] = false,
					["-"] = false,
				},
			})
		end,
	},
}
