local MiniTest = require("mini.test")
local expect = MiniTest.expect
local saved, menu, adapter, calls

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
				"atusy.lsp.skkelua",
			}) do
				saved[name] = package.loaded[name]
			end
			menu = { visible = false, selected = 0, items = {}, confirmed = true }
			calls = {}
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
			}
			package.loaded["skkelua.lsp"] = { start = function() end }
			package.loaded["atusy.lsp.skkelua"] = nil
			require("atusy.lsp.skkelua").setup()
		end,
		post_case = function()
			for name, value in pairs(saved) do
				package.loaded[name] = value
			end
			pcall(vim.api.nvim_del_augroup_by_name, "atusy.skkelua.lsp")
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
	expect.equality(adapter.confirm(), vim.keycode("<Cmd>lua require('atusy.lsp.skkelua').confirm()<CR>"))
end

T["confirming delegates to laser, whose candidate command lets skkelua learn"] = function()
	local provider = require("atusy.lsp.skkelua")
	menu.visible, menu.items, menu.selected = true, { candidate("漢字") }, 1
	expect.equality(provider.confirm(), true)
	expect.equality(calls, { "confirm" })
	menu.confirmed = false
	expect.equality(provider.confirm(), false)
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

T["guard lets completion UIs replace the pre-edit with fed <BS>"] = function()
	local guarded = {}
	package.loaded["skkelua.guard"] = {
		_on_key = function(key, typed)
			table.insert(guarded, { key, typed })
			return ""
		end,
	}
	local provider = require("atusy.lsp.skkelua")
	provider.allow_fed_backspace()
	provider.allow_fed_backspace()
	local on_key = package.loaded["skkelua.guard"]._on_key
	local bs, left = vim.keycode("<BS>"), vim.keycode("<Left>")
	expect.equality(on_key(bs, ""), nil)
	expect.equality(guarded, {})
	expect.equality(on_key(bs, bs), "")
	expect.equality(on_key(left, ""), "")
	local reg_executing = vim.fn.reg_executing
	vim.fn.reg_executing = function()
		return "q"
	end
	local ok, result = pcall(on_key, bs, "")
	vim.fn.reg_executing = reg_executing
	expect.equality({ ok, result }, { true, "" })
	expect.equality(guarded, { { bs, bs }, { left, "" }, { bs, "" } })
end

return T
