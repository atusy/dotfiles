local wezterm = require("wezterm")

wezterm.on("format-tab-title", function(window, pane)
	local pane_title = window.active_pane.title
	local user_title = window.active_pane.user_vars.panetitle

	if user_title ~= nil and #user_title > 0 then
		pane_title = user_title
	end

	return { { Text = " " .. pane_title .. " " } }
end)

return {
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	font = wezterm.font("UDEV Gothic NF"),
	-- font = wezterm.font_with_fallback({
	-- 	"UDEV Gothic NF",
	-- 	"Noto Color Emoji",
	-- }),
	font_size = wezterm.target_triple == "x86_64-unknown-linux-gnu" and 12 or 15,
	keys = {
		{
			key = "v",
			mods = "ALT|CTRL",
			action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
		},
		{ key = "s", mods = "ALT|CTRL", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
		{ key = "w", mods = "ALT|CTRL", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
		{ key = "h", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
		{ key = "l", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
		{ key = "k", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
		{ key = "j", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
	},
	color_scheme = "Afterglow",
	adjust_window_size_when_changing_font_size = false,
	exit_behavior = "Close",
	check_for_updates = false,
	use_ime = false,
}
