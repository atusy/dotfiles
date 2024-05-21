local directions = {
	h = "Left",
	j = "Down",
	k = "Up",
	l = "Right",
}

local move_nvim_win_or_wezterm_pane = function(hjkl)
	local oldwin = vim.api.nvim_get_current_win()
	vim.cmd.wincmd(hjkl)
	local newwin = vim.api.nvim_get_current_win()
	if oldwin ~= newwin then
		return
	end

	local pane = require("wezterm").get_pane_direction(directions[hjkl])
	if pane then
		require("wezterm").switch_pane.id(pane)
	end
end

return {
	{
		"https://github.com/willothy/wezterm.nvim",
		lazy = true,
		cond = function()
			return vim.env.WEZTERM_PANE ~= nil
		end,
		init = function(p)
			if not p.cond then
				return
			end
			for k, _ in pairs(directions) do
				vim.keymap.set("n", "<c-w>" .. k, function()
					move_nvim_win_or_wezterm_pane(k)
				end)
			end
		end,
	},
}
