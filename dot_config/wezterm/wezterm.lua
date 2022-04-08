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

return {
  default_prog = {"/usr/bin/env", "zsh"},
  font = wezterm.font_with_fallback({
    {family = "UDEV Gothic"},
    {family = "Noto Color Emoji"},
  }),
  font_size = 12,
  keys = {
    {key = "e", mods = "ALT", action = wezterm.action {EmitEvent = "trigger-nvim-with-scrollback"}},
    {key = "v", mods = "ALT", action = wezterm.action {SplitHorizontal = {domain = "CurrentPaneDomain"}}},
    {key = "s", mods = "ALT", action = wezterm.action {SplitVertical = {domain = "CurrentPaneDomain"}}},
    {key = "w", mods = "ALT", action = wezterm.action {CloseCurrentPane = {confirm = true}}},
    {key = "h", mods = "ALT",
      action = wezterm.action{ActivatePaneDirection = "Left"}},
    {key = "l", mods = "ALT",
      action = wezterm.action{ActivatePaneDirection = "Right"}},
    {key = "k", mods = "ALT",
      action = wezterm.action{ActivatePaneDirection = "Up"}},
    {key = "j", mods = "ALT",
      action = wezterm.action{ActivatePaneDirection = "Down"}},
  },
  color_scheme = "Afterglow",
}
