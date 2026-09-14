vim.opt.rtp:prepend(vim.fn.getcwd() .. "/dot_config/nvim")
vim.opt.rtp:prepend(assert(vim.env.SKKELUA_PATH, "SKKELUA_PATH is required"))
local skk = require("skkelua")
local provider = require("atusy.lsp.skkelua")
local tmp = vim.fn.tempname()
skk.config({
	globalDictionaries = {},
	userDictionary = tmp,
	immediatelyDictionaryRW = false,
	indicator = { enabled = false },
})
skk._handle_request("enable", {}, { mode = "", prevInput = "", completeInfo = {}, completeType = "" })
local lib = require("skkelua.store").get_library()
lib:register_henkan_result("okurinasi", "かんじ", "漢字")
for _, key in ipairs({ "K", "a", "n", "j", "i" }) do
	skk._handle_request(
		"handleKey",
		{ key = { key } },
		{ mode = "", prevInput = skk.get_pre_edit(), completeInfo = {}, completeType = "" }
	)
end
assert(skk.get_pre_edit() == "▽かんじ", skk.get_pre_edit())
local text = "😀 echo " .. skk.get_pre_edit()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
local mode = "i"
local original_mode = vim.fn.mode
vim.fn.mode = function()
	return mode
end
local function request(client, uri)
	local response = assert(client:request_sync("textDocument/completion", {
		textDocument = { uri = uri },
		position = { line = 0, character = #text },
	}, 3000, vim.api.nvim_get_current_buf()))
	assert(not response.err, vim.inspect(response))
	return response.result
end
local attaches = 0
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		attaches = attaches + 1
	end,
})
provider.setup()
vim.api.nvim_exec_autocmds("InsertEnter", {})
local id = assert(vim.lsp.get_clients({ name = "skkelua", _uninitialized = true })[1]).id
assert(require("skkelua.lsp").start(nil, provider.get_context) == id)
local client = vim.lsp.get_client_by_id(id)
assert(vim.wait(3000, function()
	return client.initialized
end))
assert(client.offset_encoding == "utf-8")
local result = request(client, vim.uri_from_bufnr(0))
assert(#result.items == 2, vim.inspect(result)) -- candidate plus registration
assert(result.items[1].textEdit.range.start.character == #"😀 echo ", vim.inspect(result))
assert(result.items[1].insertText == "漢字")
assert(result.items[2].insertText == skk.get_pre_edit())
local learned
local original = skk.complete_callback
skk.complete_callback = function(midasi, word, kind)
	learned = { midasi, word, kind }
	original(midasi, word, kind)
end
provider.on_complete_done({ __sourceName = "skkelua", user_data = { lspitem = vim.json.encode(result.items[1]) } })
assert(learned and learned[1] == "かんじ" and learned[2] == "漢字")
assert(#request(client, "file:///unrelated.txt").items == 0)
local alias = vim.uri_from_bufnr(0)
assert(#request(client, alias).items == 2)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "stale" })
assert(#request(client, alias).items == 0)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
mode = "c"
assert(#request(client, alias).items == 0)
local virtual = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(virtual, "ddc://skkelua-test")
vim.bo[virtual].filetype = "ddc_skkelua"
vim.api.nvim_buf_set_lines(virtual, 0, -1, false, { text })
local cmd_id = assert(vim.lsp.get_clients({ name = "skkelua", bufnr = virtual })[1]).id
assert(cmd_id == id, "Insert and cmdline must share a single client")
assert(require("skkelua.lsp").start(virtual, provider.get_context) == id)
assert(attaches == 2, "each buffer should attach only once")
local cmd_client = client
-- ddc owns live command-line freshness checks; resolve its request snapshot.
local cmd_result = request(cmd_client, vim.uri_from_bufnr(virtual))
assert(#cmd_result.items == 2, vim.inspect(cmd_result))
vim.bo[virtual].filetype = "unrelated"
assert(#request(client, vim.uri_from_bufnr(virtual)).items == 0)
vim.bo[virtual].filetype = "ddc_skkelua"
-- SKK still rejects a document that does not contain the current pre-edit.
vim.api.nvim_buf_set_lines(virtual, 0, -1, false, { "stale" })
assert(#request(client, vim.uri_from_bufnr(virtual)).items == 0)
vim.api.nvim_buf_set_lines(virtual, 0, -1, false, { text })
learned = nil
require("skkelua.completion").accept(provider.item({
	__sourceName = "skkelua-cmdline",
	user_data = { lspitem = vim.json.encode(cmd_result.items[1]) },
	abbr = "漢字",
	word = "😀 echo 漢字",
}))
assert(learned and learned[1] == "かんじ" and learned[2] == "漢字", "cmdline candidate did not learn")
learned = nil
require("skkelua.completion").accept(
	provider.item({ __sourceName = "skkelua-cmdline", abbr = "漢字", word = "unrelated 漢字" })
)
assert(learned == nil, "unrelated cmdline candidate was accepted")
assert(
	provider.item({ __sourceName = "skkelua-cmdline", user_data = { lspitem = vim.json.encode(cmd_result.items[2]) } }).data.register
)
mode = "n"
assert(#request(client, alias).items == 0)
mode = "i"
assert(#request(cmd_client, vim.uri_from_bufnr(virtual)).items == 0)
skk._handle_request("disable", {}, { mode = "", prevInput = skk.get_pre_edit(), completeInfo = {}, completeType = "" })
assert(#request(client, alias).items == 0)
vim.fn.mode = original_mode
client:stop(true)
cmd_client:stop(true)
vim.api.nvim_buf_delete(virtual, { force = true })
vim.fn.delete(tmp)
print("PASS SKK shared API: UTF-8 RPC, Insert/cmdline, metadata, stale text and disabled state")
