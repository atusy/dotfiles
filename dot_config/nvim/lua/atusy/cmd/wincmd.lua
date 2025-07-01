local M = {}

--- hjkl to switch windows, tmux panes, or wezterm panes
for k, opts in pairs({
	h = {
		tmux_display_message = "#{pane_at_left}",
		tmux_select_pane = "-L",
		wezterm_activate_pane = "Left",
	},
	j = {
		tmux_display_message = "#{pane_at_below}",
		tmux_select_pane = "-D",
		wezterm_activate_pane = "Down",
	},
	k = {
		tmux_display_message = "#{pane_at_above}",
		tmux_select_pane = "-U",
		wezterm_activate_pane = "Up",
	},
	l = {
		tmux_display_message = "#{pane_at_right}",
		tmux_select_pane = "-R",
		wezterm_activate_pane = "Right",
	},
}) do
	M[k] = function()
		local win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd(k)
		if vim.api.nvim_get_current_win() ~= win then
			return
		end
		if
			vim.env.TMUX ~= nil
			and vim.system({ "tmux", "display-message", "-p", opts.tmux_display_message }):wait().stdout:match("0")
		then
			vim.system({ "tmux", "select-pane", opts.tmux_select_pane })
			return
		end
		if vim.env.WEZTERM_PANE ~= nil then
			if win == vim.api.nvim_get_current_win() then
				vim.system({ "wezterm", "cli", "activate-pane-direction", opts.wezterm_activate_pane })
			end
		end
	end
end

return M
