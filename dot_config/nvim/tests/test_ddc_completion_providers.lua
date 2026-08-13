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

local function history_provider(histories, paths)
	local calls = {}
	local provider = require("atusy.lsp.ddc_completion").make_history_provider({
		gethistory = function(cmd_type, limit)
			table.insert(calls, { cmd_type, limit })
			return histories
		end,
		isdirectory = function(path)
			return paths and paths[path] == "dir" or false
		end,
		isfile = function(path)
			return paths and paths[path] == "file" or false
		end,
	}, 1000)
	return provider, calls
end

T["history provider keeps newest-first full entries before a space"] = function()
	local provider, calls = history_provider({ "write", "wall" })
	local result = provider(request(":", "command", "w"), { text = "w", version = 1 })
	expect.equality(calls, { { ":", 1000 } })
	expect.equality(result.items, { { label = "write" }, { label = "wall" } })
end

T["history provider returns matching suffixes after a space"] = function()
	local provider = history_provider({ "git checkout main", "git status", "make test" })
	local params = request(":", "shellcmd", "git ch")
	params.xDdc.completePos = 4
	local result = provider(params, { text = "git ch", version = 1 })
	expect.equality(result.items, { { label = "checkout main" }, { label = "status" } })
end

T["history provider rejects multiline entries"] = function()
	local provider = history_provider({ "git status\nquit", "git status" })
	local params = request(":", "shellcmd", "git s")
	params.xDdc.completePos = 4
	local result = provider(params, { text = "git s", version = 1 })
	expect.equality(result.items, { { label = "status" } })
end

T["history provider filters file and directory completion types"] = function()
	local histories = { "/tmp/missing", "/tmp/file", "/tmp/dir" }
	local paths = { ["/tmp/file"] = "file", ["/tmp/dir"] = "dir" }
	local provider = history_provider(histories, paths)
	local files = provider(request(":", "file", "/tmp/"), { text = "/tmp/", version = 1 })
	local dirs = provider(request(":", "dir", "/tmp/"), { text = "/tmp/", version = 1 })
	expect.equality(files.items, { { label = "/tmp/file" }, { label = "/tmp/dir" } })
	expect.equality(dirs.items, { { label = "/tmp/dir" } })
end

local function cmdline_provider(results)
	local calls = {}
	local provider = require("atusy.lsp.ddc_completion").make_cmdline_provider({
		getcompletion = function(input, completion_type)
			table.insert(calls, { input, completion_type })
			return results
		end,
	})
	return provider, calls
end

T["cmdline provider excludes unsupported command types"] = function()
	for _, cmd_type in ipairs({ "/", "?", ">", "=", "@" }) do
		local provider, calls = cmdline_provider({ "unused" })
		local result = provider(request(cmd_type, "", "x"), { text = "x", version = 1 })
		expect.equality(result.items, {})
		expect.equality(calls, {})
	end
end

T["cmdline provider completes Ex commands and buffers"] = function()
	local provider, calls = cmdline_provider({ "buffer", "bdelete" })
	local result = provider(request(":", "command", "b"), { text = "b", version = 1 })
	expect.equality(calls, { { "b", "cmdline" } })
	expect.equality(result.items, { { label = "buffer" }, { label = "bdelete" } })
end

T["cmdline provider restores no-prefixed set options"] = function()
	local provider = cmdline_provider({ "ignorecase" })
	local params = request(":", "option", "set noig")
	params.xDdc.completePos = 4
	local result = provider(params, { text = "set noig", version = 1 })
	expect.equality(result.items, { { label = "noignorecase" } })
end

T["cmdline provider head-filters help tags"] = function()
	local provider = cmdline_provider({ "lua-guide", "vim.lua", "lua.txt" })
	local result = provider(request(":", "help", "help lua"), { text = "help lua", version = 1 })
	expect.equality(result.items, { { label = "lua-guide" }, { label = "lua.txt" } })
end

T["cmdline provider preserves absolute and tilde paths"] = function()
	local absolute = cmdline_provider({ "/Users/atusy/file" })
	local tilde = cmdline_provider({ "~/file" })
	expect.equality(
		absolute(request(":", "file", "edit /Users/atusy/f"), {
			text = "edit /Users/atusy/f",
			version = 1,
		}).items,
		{ { label = "/Users/atusy/file" } }
	)
	expect.equality(
		tilde(request(":", "file", "edit ~/f"), {
			text = "edit ~/f",
			version = 1,
		}).items,
		{ { label = "~/file" } }
	)
end

T["cmdline provider completes from text before a middle cursor"] = function()
	local provider, calls = cmdline_provider({ "getbuffer" })
	local params = request(":", "function", "call getb")
	params.position.character = 8
	local result = provider(params, { text = "call getb()", version = 1 })
	expect.equality(calls, { { "call get", "cmdline" } })
	expect.equality(result.items, { { label = "getbuffer" } })
end

return T
