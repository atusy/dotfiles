local wezterm = require("wezterm")

wezterm.on("format-tab-title", function(window, pane)
	local pane_title = window.active_pane.title
	local user_title = window.active_pane.user_vars.panetitle

	if user_title ~= nil and #user_title > 0 then
		pane_title = user_title
	end

	return { { Text = " " .. pane_title .. " " } }
end)

local default_opacity = 0.80

wezterm.on("increase-opacity", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if not overrides.window_background_opacity then
		overrides.window_background_opacity = default_opacity
	end
	overrides.window_background_opacity = math.min(1, overrides.window_background_opacity + 0.03)
	window:set_config_overrides(overrides)
end)

wezterm.on("decrease-opacity", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if not overrides.window_background_opacity then
		overrides.window_background_opacity = default_opacity
	end
	overrides.window_background_opacity = math.max(0, overrides.window_background_opacity - 0.03)
	window:set_config_overrides(overrides)
end)

return {
	window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	font = wezterm.font_with_fallback({
		{ family = "UDEV Gothic NF" },
		{ family = "Noto Color Emoji" },
	}),
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
		{ key = "d", mods = "ALT|CTRL", action = wezterm.action.EmitEvent("decrease-opacity") },
		{ key = "u", mods = "ALT|CTRL", action = wezterm.action.EmitEvent("increase-opacity") },
	},
	color_scheme = "Afterglow",
	window_background_opacity = 1,
	-- window_background_opacity = 0.93,
	adjust_window_size_when_changing_font_size = false,
	exit_behavior = "Close",
	check_for_updates = false,
	use_ime = false,
	front_end = "WebGpu",
}
