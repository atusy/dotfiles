local directions = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function move_nvim_win_or_wezterm_pane(hjkl)
	local win = vim.api.nvim_get_current_win()
	vim.cmd.wincmd(hjkl)
	if win == vim.api.nvim_get_current_win() then
		require("wezterm").switch_pane.direction(directions[hjkl])
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
