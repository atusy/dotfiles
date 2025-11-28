local function setup_winbar()
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

local function open()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	for _, win in ipairs(wins) do
		local buf = vim.api.nvim_win_get_buf(win)
		local nm = vim.api.nvim_buf_get_name(buf)
		if vim.startswith(nm, "fyler://") then
			vim.api.nvim_set_current_win(win)
			return
		end
	end

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
			setup_winbar()
			vim.keymap.set("n", "S", open)
		end,
		config = function()
			require("fyler").setup({
				views = {
					finder = {
						close_on_select = false,
						confirm_simple = true,
						follow_current_file = false,
						mappings = require("plugins.fyler.mappings"),
					},
				},
			})
		end,
	},
}
