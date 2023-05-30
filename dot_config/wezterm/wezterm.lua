local wezterm = require("wezterm")

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane_title = tab.active_pane.title
  local user_title = tab.active_pane.user_vars.panetitle

  if user_title ~= nil and #user_title > 0 then
    pane_title = user_title
  end

  return {
    --{Background={Color="black"}},
    --{Foreground={Color="white"}},
    { Text = " " .. pane_title .. " " },
  }
end)

return {
  default_prog = { "/usr/bin/env", "zsh" },
  font = wezterm.font_with_fallback({
    { family = "UDEV Gothic NF" },
    { family = "Noto Color Emoji" },
  }),
  font_size = 11,
  keys = {
    { key = "e", mods = "ALT|CTRL", action = wezterm.action({ EmitEvent = "trigger-nvim-with-scrollback" }) },
    { key = "v", mods = "ALT|CTRL", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
    { key = "s", mods = "ALT|CTRL", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
    { key = "w", mods = "ALT|CTRL", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
    { key = "h", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
    { key = "l", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
    { key = "k", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
    { key = "j", mods = "ALT|CTRL", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
  },
  color_scheme = "Afterglow",
  -- window_background_opacity = 0.98,
  adjust_window_size_when_changing_font_size = false,
  exit_behavior = "Close",
  check_for_updates = false,
  use_ime = true,
}
