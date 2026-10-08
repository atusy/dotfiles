-- Pure logic for dockswitcher (no hs.* dependency, testable with plain Lua).
local M = {}

local FINDER = "com.apple.finder"

-- Presses of the same key within this many seconds continue the current cycle.
M.cycleTimeout = 1.0

-- Bundle IDs in visible Dock order.
-- Finder is always the leftmost Dock item but is usually absent from persistent-apps.
function M.dockApps(dockPlist)
  local apps = { FINDER }
  local items = dockPlist and dockPlist["persistent-apps"] or {}
  for _, item in ipairs(items) do
    local bundleID = item["tile-data"] and item["tile-data"]["bundle-identifier"]
    if bundleID and bundleID ~= FINDER then
      table.insert(apps, bundleID)
    end
  end
  return apps
end

local function contains(list, value)
  for _, v in ipairs(list) do
    if v == value then return true end
  end
  return false
end

-- Decide what a press does. Returns one of:
--   { focus = windowID }  focus that window
--   { hide = true }       hide the app (single window that is already frontmost)
--   { launch = true }     no usable window: launch or reopen like a Dock click
-- state: mutable table kept across presses.
-- press: { bundleID, now, frontmost (target app is frontmost), mru (window ids, most recent first) }
-- The order is frozen for the duration of a rapid-press cycle; otherwise focusing a window
-- would move it to the MRU head and the cycle would bounce between the top two windows.
function M.nextAction(state, press)
  local mru = press.mru
  if #mru == 0 then
    state.cycle = nil
    return { launch = true }
  end
  if #mru == 1 then
    state.cycle = nil
    return press.frontmost and { hide = true } or { focus = mru[1] }
  end

  local cycle = state.cycle
  if cycle and cycle.bundleID == press.bundleID and press.now - cycle.lastPress <= M.cycleTimeout then
    for _ = 1, #cycle.order do
      cycle.index = cycle.index % #cycle.order + 1
      local id = cycle.order[cycle.index]
      if contains(mru, id) then
        cycle.lastPress = press.now
        return { focus = id }
      end
    end
  end

  local index = press.frontmost and 2 or 1
  state.cycle = { bundleID = press.bundleID, order = mru, index = index, lastPress = press.now }
  return { focus = mru[index] }
end

return M
