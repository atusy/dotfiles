-- Run: luajit tests/core_test.lua  (from ~/.hammerspoon)
package.path = "./?.lua;./?/init.lua;" .. package.path
local core = require("dockswitcher.core")

local tests = {}
local function test(name, fn) table.insert(tests, { name = name, fn = fn }) end

local function eq(actual, expected, path)
  path = path or "value"
  if type(expected) == "table" then
    assert(type(actual) == "table", path .. ": expected table, got " .. tostring(actual))
    for k, v in pairs(expected) do eq(actual[k], v, path .. "." .. tostring(k)) end
    for k in pairs(actual) do
      assert(expected[k] ~= nil, path .. ": unexpected key " .. tostring(k))
    end
  else
    assert(actual == expected,
      path .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

local function tile(bundleID) return { ["tile-data"] = { ["bundle-identifier"] = bundleID } } end

-- dockApps

test("dockApps puts Finder first", function()
  eq(core.dockApps({ ["persistent-apps"] = { tile("a"), tile("b") } }),
    { "com.apple.finder", "a", "b" })
end)

test("dockApps does not duplicate Finder", function()
  eq(core.dockApps({ ["persistent-apps"] = { tile("a"), tile("com.apple.finder") } }),
    { "com.apple.finder", "a" })
end)

test("dockApps skips tiles without bundle identifier", function()
  eq(core.dockApps({ ["persistent-apps"] = { tile("a"), { ["tile-data"] = {} }, {}, tile("b") } }),
    { "com.apple.finder", "a", "b" })
end)

test("dockApps tolerates missing plist", function()
  eq(core.dockApps(nil), { "com.apple.finder" })
end)

-- nextAction

local function newState() return {} end

test("first press from another app focuses most recent window", function()
  local s = newState()
  local id = core.nextAction(s, { bundleID = "x", now = 0, frontmost = false, mru = { 3, 1, 2 } })
  eq(id, { focus = 3 })
end)

test("first press while app is frontmost focuses second most recent window", function()
  local s = newState()
  local id = core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 3, 1, 2 } })
  eq(id, { focus = 1 })
end)

test("rapid presses cycle through the order frozen at the first press", function()
  local s = newState()
  local ids = {}
  -- mru reported by the system changes as windows get focused, but must be ignored mid-cycle
  ids[1] = core.nextAction(s, { bundleID = "x", now = 0.0, frontmost = true, mru = { 3, 1, 2 } })
  ids[2] = core.nextAction(s, { bundleID = "x", now = 0.3, frontmost = true, mru = { 1, 3, 2 } })
  ids[3] = core.nextAction(s, { bundleID = "x", now = 0.6, frontmost = true, mru = { 2, 1, 3 } })
  ids[4] = core.nextAction(s, { bundleID = "x", now = 0.9, frontmost = true, mru = { 3, 2, 1 } })
  eq(ids, { { focus = 1 }, { focus = 2 }, { focus = 3 }, { focus = 1 } })
end)

test("timeout starts a new cycle from fresh MRU order", function()
  local s = newState()
  core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 3, 1, 2 } })
  local id = core.nextAction(s, { bundleID = "x", now = 5, frontmost = true, mru = { 1, 3, 2 } })
  eq(id, { focus = 3 }) -- ⌘Tab-like toggle between the two most recent windows
end)

test("switching to another app starts a new cycle", function()
  local s = newState()
  core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 3, 1, 2 } })
  local id = core.nextAction(s, { bundleID = "y", now = 0.1, frontmost = false, mru = { 7, 8 } })
  eq(id, { focus = 7 })
end)

test("closed windows are skipped mid-cycle", function()
  local s = newState()
  core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 3, 1, 2 } })
  local id = core.nextAction(s, { bundleID = "x", now = 0.3, frontmost = true, mru = { 3, 2 } })
  eq(id, { focus = 2 })
end)

test("single window of a background app is focused", function()
  local s = newState()
  eq(core.nextAction(s, { bundleID = "x", now = 0, frontmost = false, mru = { 5 } }), { focus = 5 })
end)

test("single window of the frontmost app hides the app", function()
  local s = newState()
  eq(core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 5 } }), { hide = true })
end)

test("closing all but one window mid-cycle hides instead of cycling", function()
  local s = newState()
  core.nextAction(s, { bundleID = "x", now = 0, frontmost = true, mru = { 3, 1 } })
  eq(core.nextAction(s, { bundleID = "x", now = 0.3, frontmost = true, mru = { 1 } }), { hide = true })
end)

test("no windows asks to launch (reopen)", function()
  local s = newState()
  eq(core.nextAction(s, { bundleID = "x", now = 0, frontmost = false, mru = {} }), { launch = true })
end)

local failed = 0
for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if ok then
    print("ok   " .. t.name)
  else
    failed = failed + 1
    print("FAIL " .. t.name .. "\n     " .. tostring(err))
  end
end
print(string.format("%d tests, %d failed", #tests, failed))
os.exit(failed == 0 and 0 or 1)
