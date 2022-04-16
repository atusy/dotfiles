local wezterm = require("wezterm")
wezterm.on("trigger-nvim-with-scrollback", function(window, pane)
  local scrollback = pane:get_lines_as_text()
  local name = os.tmpname()
  local f = io.open(name, "w+")
  f:write(scrollback)
  f:flush()
  f:close()
  window:perform_action(
    wezterm.action({SpawnCommandInNewTab = {
      args = {"nvim", name},
    }}),
    pane
  )
  wezterm.sleep_ms(1000)
  os.remove(name)
end)

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane_title = tab.active_pane.title
  local user_title = tab.active_pane.user_vars.panetitle

  if user_title ~= nil and #user_title > 0 then
    pane_title = user_title
  end

  return {
    --{Background={Color="black"}},
    --{Foreground={Color="white"}},
    {Text=" " .. pane_title .. " "},
  }
end)

return {
  default_prog = {"/usr/bin/env", "zsh"},
  font = wezterm.font_with_fallback({
    {family = "UDEV Gothic"},
    {family = "Noto Color Emoji"},
  }),
  font_size = 12,
  keys = {
    {key = "e", mods = "ALT|CTRL", action = wezterm.action {EmitEvent = "trigger-nvim-with-scrollback"}},
    {key = "v", mods = "ALT|CTRL", action = wezterm.action {SplitHorizontal = {domain = "CurrentPaneDomain"}}},
    {key = "s", mods = "ALT|CTRL", action = wezterm.action {SplitVertical = {domain = "CurrentPaneDomain"}}},
    {key = "w", mods = "ALT|CTRL", action = wezterm.action {CloseCurrentPane = {confirm = true}}},
    {key = "h", mods = "ALT|CTRL",
      action = wezterm.action{ActivatePaneDirection = "Left"}},
    {key = "l", mods = "ALT|CTRL",
      action = wezterm.action{ActivatePaneDirection = "Right"}},
    {key = "k", mods = "ALT|CTRL",
      action = wezterm.action{ActivatePaneDirection = "Up"}},
    {key = "j", mods = "ALT|CTRL",
      action = wezterm.action{ActivatePaneDirection = "Down"}},
  },
  color_scheme = "Afterglow",
}
