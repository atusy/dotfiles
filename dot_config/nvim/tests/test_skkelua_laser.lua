local MiniTest = require("mini.test")
local expect = MiniTest.expect
local saved, menu

local function candidate(label)
	return { word = label, user_data = { laser = { item = { label = label, data = { skkelua = true } } } } }
end

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			saved = {}
			for _, name in ipairs({
				"laser",
				"skkelua",
				"skkelua.guard",
				"skkelua.lsp",
				"plugins.skkelua.laser",
			}) do
				saved[name] = package.loaded[name]
			end
			menu = { visible = false, selected = 0, items = {} }
			package.loaded.laser = {
				visible = function()
					return menu.visible
				end,
				get_selected = function()
					local selected = menu.visible and menu.items[menu.selected]
					return selected and selected.user_data.laser.item or nil
				end,
			}
			package.loaded["skkelua.lsp"] = { start = function() end }
			package.loaded["plugins.skkelua.laser"] = nil
			require("plugins.skkelua.laser").setup()
		end,
		post_case = function()
			for name, value in pairs(saved) do
				package.loaded[name] = value
			end
			pcall(vim.api.nvim_del_augroup_by_name, "atusy.skkelua.laser")
		end,
	},
})

T["<C-g> restores a selected candidate before cancelling SKK"] = function()
	local provider = require("plugins.skkelua.laser")
	local laser_cancel = "<Cmd>lua require('laser').cancel()<CR>"
	local skk_cancel = "<Cmd>lua require('skkelua').handle('handleKey', { key = '<C-g>' })<CR>"
	expect.equality(provider.cancel_keys(), skk_cancel)
	menu.visible, menu.items = true, { candidate("漢字") }
	expect.equality(provider.cancel_keys(), laser_cancel .. skk_cancel)
	menu.selected = 1
	expect.equality(provider.cancel_keys(), laser_cancel)
end

return T
