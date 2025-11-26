local L = {}
function L.cb(opts)
	vim.keymap.set("n", "#", function()
		local cdir = vim.fs.dirname(opts.cfile)
		if vim.uv.fs_stat(opts.cfile) then
			L.open({ dir = cdir, cfile = opts.cfile })
		end
	end, { buffer = true })
	vim.keymap.set("n", "<c-s>", function()
		require("oil").save(true)
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
		init = function()
			vim.api.nvim_create_autocmd("BufWinEnter", {
				callback = function(ctx)
					if not vim.startswith(ctx.file, "oil://") then
						return
					end
					if not vim.w.old_winbar then
						vim.w.old_winbar = vim.wo[0].winbar
					end
					vim.wo[0].winbar = "%F"
				end,
			})

			vim.api.nvim_create_autocmd("BufWinLeave", {
				callback = function()
					if vim.w.old_winbar then
						vim.wo[0].winbar = vim.w.old_winbar
						vim.w.old_winbar = nil
					end
				end,
			})

			vim.keymap.set("n", "S", function()
				L.open({ cfile = vim.api.nvim_buf_get_name(0) })
			end)
		end,
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
