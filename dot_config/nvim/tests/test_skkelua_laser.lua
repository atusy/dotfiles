local MiniTest = require("mini.test")
local expect = MiniTest.expect
local saved, menu, adapter, accepted, calls

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
				"skkelua.lsp",
				"atusy.lsp.skkelua",
			}) do
				saved[name] = package.loaded[name]
			end
			menu = { visible = false, selected = 0, items = {}, confirmed = true }
			accepted, calls = {}, {}
			package.loaded.laser = {
				visible = function()
					return menu.visible
				end,
				confirm = function()
					table.insert(calls, "confirm")
					return menu.confirmed
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
				accept = function(item)
					table.insert(calls, "accept")
					table.insert(accepted, item)
				end,
			}
			package.loaded["skkelua.lsp"] = { start = function() end }
			package.loaded["atusy.lsp.skkelua"] = nil
			require("atusy.lsp.skkelua").setup({ trigger = function() end })
		end,
		post_case = function()
			for name, value in pairs(saved) do
				package.loaded[name] = value
			end
			pcall(vim.api.nvim_del_augroup_by_name, "atusy.skkelua.lsp")
		end,
	},
})

T["adapter reports laser's menu and selection"] = function()
	expect.equality(adapter.state(), { visible = false })
	menu.visible, menu.items = true, { candidate("漢字"), candidate("感じ") }
	expect.equality(adapter.state(), { visible = true })
	menu.selected = 2
	expect.equality(adapter.state(), {
		visible = true,
		selected = { word = "感じ", item = menu.items[2].user_data.laser.item },
	})
end

T["adapter confirms through laser"] = function()
	expect.equality(adapter.confirm(), vim.keycode("<Cmd>lua require('atusy.lsp.skkelua').confirm()<CR>"))
end

T["confirming a selected candidate accepts its item"] = function()
	local provider = require("atusy.lsp.skkelua")
	menu.visible, menu.items, menu.selected = true, { candidate("漢字") }, 1
	expect.equality(provider.confirm(), true)
	expect.equality(calls, { "confirm", "accept" })
	expect.equality(accepted, { menu.items[1].user_data.laser.item })
end

T["confirming without a selection accepts nothing"] = function()
	local provider = require("atusy.lsp.skkelua")
	menu.visible, menu.items, menu.selected, menu.confirmed = true, { candidate("漢字") }, 0, false
	expect.equality(provider.confirm(), false)
	expect.equality(accepted, {})
end

T["<C-g> restores a selected candidate before cancelling SKK"] = function()
	local provider = require("atusy.lsp.skkelua")
	local laser_cancel = "<Cmd>lua require('laser').cancel()<CR>"
	local skk_cancel = "<Cmd>lua require('skkelua').handle('handleKey', { key = '<C-g>' })<CR>"
	expect.equality(provider.cancel_keys(), skk_cancel)
	menu.visible, menu.items = true, { candidate("漢字") }
	expect.equality(provider.cancel_keys(), laser_cancel .. skk_cancel)
	menu.selected = 1
	expect.equality(provider.cancel_keys(), laser_cancel)
end

return T
