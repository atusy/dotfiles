local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set()

local function new_client(provider)
	local replies = {}
	local exits = {}
	local rpc = require("atusy.lsp.ddc_completion").create({
		on_exit = function(code, signal)
			table.insert(exits, { code, signal })
		end,
	}, { provider = provider })
	return rpc, replies, exits
end

local function request(rpc, method, params)
	local response
	local replied = {}
	local ok, id = rpc.request(method, params, function(err, result, response_id)
		response = { err = err, result = result, id = response_id }
	end, function(response_id)
		table.insert(replied, response_id)
	end)
	return ok,
		id,
		function()
			vim.wait(1000, function()
				return response ~= nil
			end)
			return response, replied
		end
end

T["initialize advertises completion and incremental document sync"] = function()
	local rpc = new_client(function()
		return {}
	end)
	local ok, id, await = request(rpc, "initialize", {})
	expect.equality({ ok, id }, { true, 1 })
	local response, replied = await()
	expect.equality(response.result.capabilities.completionProvider, {})
	expect.equality(response.result.capabilities.textDocumentSync, { openClose = true, change = 2 })
	expect.equality(replied, { 1 })
end

T["request ids increase and unknown methods settle once"] = function()
	local rpc = new_client(function()
		return {}
	end)
	local _, first = request(rpc, "initialize", {})
	local _, second, await = request(rpc, "unknown/method", {})
	expect.equality({ first, second }, { 1, 2 })
	local response, replied = await()
	expect.equality(response.err.code, vim.lsp.protocol.ErrorCodes.MethodNotFound)
	expect.equality(replied, { 2 })
end

T["cancelled completion cannot return a stale result"] = function()
	local rpc = new_client(function()
		return { items = { { label = "stale" } } }
	end)
	local _, id, await = request(rpc, "textDocument/completion", {
		textDocument = { uri = "untitled://ddc/test" },
		position = { line = 0, character = 1 },
	})
	rpc.notify("$/cancelRequest", { id = id })
	local response, replied = await()
	expect.equality(response.err.code, vim.lsp.protocol.ErrorCodes.RequestCancelled)
	expect.equality(response.result, nil)
	expect.equality(replied, { id })
end

T["completion observes the matching document version"] = function()
	local seen
	local rpc = new_client(function(params, document)
		seen = { params = params, document = document }
		return { items = {} }
	end)
	rpc.notify("textDocument/didOpen", {
		textDocument = { uri = "untitled://ddc/test", version = 1, text = "old" },
	})
	rpc.notify("textDocument/didChange", {
		textDocument = { uri = "untitled://ddc/test", version = 2 },
		contentChanges = { { text = "new" } },
	})
	local _, _, await = request(rpc, "textDocument/completion", {
		textDocument = { uri = "untitled://ddc/test" },
		position = { line = 0, character = 3 },
		xDdc = { cmdType = ":", generation = 2 },
	})
	await()
	expect.equality(seen.document, { uri = "untitled://ddc/test", version = 2, text = "new" })
	expect.equality(seen.params.xDdc, { cmdType = ":", generation = 2 })
end

T["terminate closes once and rejects later requests"] = function()
	local rpc, _, exits = new_client(function()
		return {}
	end)
	rpc.terminate()
	rpc.terminate()
	expect.equality(rpc.is_closing(), true)
	expect.equality(exits, { { 0, 0 } })
	local ok, id = rpc.request("initialize", {}, function() end)
	expect.equality({ ok, id }, { false })
end

return T
