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
local params = { position = { line = 0, character = vim.str_utfindex(text, "utf-16") } }
local result = provider.complete(params, { text = text })
assert(#result.items == 1, vim.inspect(result))
assert(result.items[1].textEdit.range.start.character == 8, vim.inspect(result))
local learned
local original = skk.complete_callback
skk.complete_callback = function(midasi, word)
	learned = { midasi, word }
	original(midasi, word)
end
-- Normal LSP source serializes the completion item as JSON.
provider.on_complete_done({ __sourceName = "skkelua", user_data = { lspitem = vim.json.encode(result.items[1]) } })
assert(learned and learned[1] == "かんじ" and learned[2] == "漢字", "ddc confirmation did not learn the candidate")
learned = nil
provider.on_complete_done({ __sourceName = "skkelua-cmdline", abbr = "漢字", word = "echo 漢字" })
assert(learned and learned[1] == "かんじ" and learned[2] == "漢字")
assert(#provider.complete(params, { text = "unrelated" }).items == 0)
-- ddc uses cwd/ for an unnamed buffer, while the LSP didOpen URI is file://.
vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
params.textDocument = { uri = vim.uri_from_fname(vim.fn.fnamemodify("", ":p")) }
assert(#provider.complete_buffer(params, nil).items == 1)
params.textDocument.uri = "file:///unrelated.txt"
assert(#provider.complete_buffer(params, nil).items == 0)
-- Exercise the real Neovim client and the synchronized document transport.
local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { text })
local id = assert(
	vim.lsp.start(
		{ name = "skkelua-test", cmd = require("atusy.lsp.ddc_completion").command(provider.complete) },
		{ bufnr = buffer }
	)
)
assert(vim.wait(3000, function()
	return vim.lsp.get_client_by_id(id).initialized
end))
local client = vim.lsp.get_client_by_id(id)
params.textDocument = { uri = vim.uri_from_bufnr(buffer) }
local response = assert(client:request_sync("textDocument/completion", params, 3000, buffer))
assert(not response.err, vim.inspect(response))
assert(response.result.items[1].label == "漢字", vim.inspect(response))
client:stop(true)
print("PASS skkelua LSP UTF-16 ranges, stale text rejection, buffer/cmdline learning, real RPC")
vim.fn.delete(tmp)
