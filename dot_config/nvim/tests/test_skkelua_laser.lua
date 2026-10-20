local MiniTest = require("mini.test")
local expect = MiniTest.expect
local saved, menu, adapter

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
				"skkelua.completion",
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
				_engine = function()
					return {
						ui = {
							selected = function()
								return menu.selected
							end,
							items = function()
								return menu.items
							end,
						},
					}
				end,
			}
			package.loaded["skkelua.completion"] = {
				set_adapter = function(value)
					adapter = value
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

T["adapter reports laser's selected item"] = function()
	expect.equality(adapter.selected(), nil)
	menu.visible, menu.items = true, { candidate("漢字"), candidate("感じ") }
	expect.equality(adapter.selected(), nil)
	menu.selected = 2
	expect.equality(adapter.selected(), menu.items[2].user_data.laser.item)
	menu.visible = false
	expect.equality(adapter.selected(), nil)
end

T["a restored pre-edit makes laser complete again"] = function()
	local completed = 0
	package.loaded["plugins.laser.completion"] = {
		complete = function()
			completed = completed + 1
		end,
	}
	vim.api.nvim_exec_autocmds("User", { pattern = "skkelua-pre-edit-restored" })
	package.loaded["plugins.laser.completion"] = nil
	expect.equality(completed, 1)
end

T["adapter confirms through laser"] = function()
	expect.equality(adapter.confirm(), vim.keycode("<Cmd>lua require('laser').confirm()<CR>"))
end

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
