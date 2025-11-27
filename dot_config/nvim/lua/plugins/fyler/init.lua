local L = {}

function L.setup_winbar()
	vim.api.nvim_create_autocmd("BufWinEnter", {
		callback = function(ctx)
			if vim.startswith(ctx.file, "fyler://") then
				if not vim.w.old_winbar then
					vim.w.old_winbar = vim.wo[0].winbar
				end
				vim.wo[0].winbar = "%F"
				return
			end

			if vim.w.old_winbar then
				vim.wo[0].winbar = vim.w.old_winbar
			end
		end,
	})
end

function L.open()
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		local nm = vim.api.nvim_buf_get_name(buf)
		if vim.startswith(nm, "fyler://") then
			vim.api.nvim_win_set_buf(0, buf)
			return
		end
	end
	if vim.v.count > 0 then
		require("fyler").close()
	end
	require("fyler").open()
end

return {
	{
		"https://github.com/A7Lavinraj/fyler.nvim",
		init = function()
			L.setup_winbar()
			vim.keymap.set("n", "S", L.open)
		end,
		config = function()
			require("fyler").setup({
				views = {
					finder = {
						follow_current_file = false,
						mappings = {
							q = false,
							K = function(finder)
								vim.print(finder)
							end,
							gf = function(finder)
								local entry = finder:cursor_node_entry()
								if entry:isdir() then
									finder:exec_action("n_select")
									return
								end
								vim.cmd.edit(vim.fn.fnameescape(entry.path))
							end,
							["<CR>"] = function(finder)
								local entry = finder:cursor_node_entry()
								if entry:isdir() then
									finder:exec_action("n_select")
									return
								end
								vim.cmd.edit(vim.fn.fnameescape(entry.path))
							end,
							["<c-s>"] = function(finder)
								finder:synchronize()
							end,
						},
					},
				},
			})
		end,
	},
}
