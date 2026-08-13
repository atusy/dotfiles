local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set()

local function input_provider(results)
	local calls = {}
	local provider = require("atusy.lsp.ddc_completion").make_input_provider({
		getcompletion = function(input, completion_type)
			table.insert(calls, { input, completion_type })
			return results
		end,
	})
	return provider, calls
end

local function request(cmd_type, completion_type, text)
	return {
		position = { line = 0, character = #text },
		xDdc = {
			cmdType = cmd_type,
			completionType = completion_type,
			completePos = 0,
			generation = 1,
		},
	}
end

T["input provider uses expression completion for equals"] = function()
	local provider, calls = input_provider({ "vim.api", "vim.bo" })
	local result = provider(request("=", "", "vim."), { text = "vim.", version = 1 })
	expect.equality(calls, { { "vim.", "expression" } })
	expect.equality(result.items, {
		{ label = "vim.api" },
		{ label = "vim.bo" },
	})
end

T["input provider observes register completion type"] = function()
	local provider, calls = input_provider({ "a", "b" })
	local result = provider(request("@", "register", ""), { text = "", version = 1 })
	expect.equality(calls, { { "", "register" } })
	expect.equality(result.items, { { label = "a" }, { label = "b" } })
end

T["input provider rejects register completion without a type"] = function()
	local provider, calls = input_provider({ "unused" })
	local result = provider(request("@", "", ""), { text = "", version = 1 })
	expect.equality(calls, {})
	expect.equality(result.items, {})
end

T["input provider preserves directory display but omits trailing slash insertion"] = function()
	local provider = input_provider({ "dir/" })
	local result = provider(request("=", "", "d"), { text = "d", version = 1 })
	expect.equality(result.items, { { label = "dir/", insertText = "dir" } })
end

return T
