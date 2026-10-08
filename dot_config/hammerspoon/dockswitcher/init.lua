-- Dock switcher: ⌘1..⌘9 activates the n-th Dock app (Finder = ⌘1);
-- repeated presses cycle its windows in MRU order.
local core = require("dockswitcher.core")

local M = {}

local DOCK_PLIST = os.getenv("HOME") .. "/Library/Preferences/com.apple.dock.plist"

M.mods = { "cmd" }

local hotkeys = {}
local state = {}
local windowFilter -- tracks focus history; must stay referenced to keep running
local dockWatcher
local rebindTimer

-- Window ids of the app (most recently focused first) and an id -> window lookup
local function mruWindows(bundleID)
  local ids, byID = {}, {}
  for _, win in ipairs(windowFilter:getWindows(hs.window.filter.sortByFocusedLast)) do
    local app = win:application()
    if app and app:bundleID() == bundleID and win:isStandard() and not win:isMinimized() then
      table.insert(ids, win:id())
      byID[win:id()] = win
    end
  end
  return ids, byID
end

local function activate(bundleID)
  local app = hs.application.get(bundleID)
  if not app then
    hs.application.launchOrFocusByBundleID(bundleID)
    return
  end

  local ids, byID = mruWindows(bundleID)
  local action = core.nextAction(state, {
    bundleID = bundleID,
    now = hs.timer.secondsSinceEpoch(),
    frontmost = app:isFrontmost(),
    mru = ids,
  })
  local win = action.focus and byID[action.focus]
  if win then
    win:focus()
  elseif action.hide then
    app:hide()
  else
    -- No usable window (e.g. all minimized, closed, or app hidden): behave like a Dock click
    hs.application.launchOrFocusByBundleID(bundleID)
  end
end

function M.bind()
  for _, hk in ipairs(hotkeys) do hk:delete() end
  hotkeys = {}

  local apps = core.dockApps(hs.plist.read(DOCK_PLIST))
  for i = 1, math.min(#apps, 9) do
    local bundleID = apps[i]
    table.insert(hotkeys, hs.hotkey.bind(M.mods, tostring(i), function() activate(bundleID) end))
  end
end

function M.start()
  -- Focus order is recorded only while the filter is active
  windowFilter = hs.window.filter.new():keepActive()

  M.bind()

  -- cfprefsd writes the plist via atomic rename, so watch the directory
  dockWatcher = hs.pathwatcher.new(DOCK_PLIST:match("^(.*)/"), function(paths)
    for _, path in ipairs(paths) do
      if path:find("com.apple.dock.plist", 1, true) then
        if rebindTimer then rebindTimer:stop() end
        rebindTimer = hs.timer.doAfter(0.5, M.bind)
        return
      end
    end
  end):start()
end

return M
