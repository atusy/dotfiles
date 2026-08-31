vim.lsp.enable("kakehashi")
vim.cmd.edit("__ignored/samples/vim-gin-completion.vim")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Gin " })

assert(
	vim.wait(10_000, function()
		return #vim.lsp.get_clients({ bufnr = 0, name = "kakehashi" }) > 0
	end, 100),
	"kakehashi did not attach"
)

vim.wait(3_000)

local response = vim.lsp.buf_request_sync(0, "textDocument/completion", {
	textDocument = { uri = vim.uri_from_bufnr(0) },
	position = { line = 0, character = 4 },
	context = { triggerKind = 1 },
}, 15_000)

local found = false
local observed = {}
for _, result in pairs(response or {}) do
	local items = result.result and (result.result.items or result.result) or {}
	for _, item in ipairs(items) do
		local origin = item.data and item.data.kakehashi and item.data.kakehashi.origin
		observed[origin or "none"] = (observed[origin or "none"] or 0) + 1
		if origin == "fish_lsp" and item.label == "add" then
			found = true
			break
		end
	end
end

vim.bo.modified = false
if not found then
	vim.api.nvim_err_writeln("Gin followed by a space did not reach fish_lsp completion: " .. vim.inspect(observed))
	vim.cmd.cquit()
end

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Gin commit " })
local commit_response = vim.lsp.buf_request_sync(0, "textDocument/completion", {
	textDocument = { uri = vim.uri_from_bufnr(0) },
	position = { line = 0, character = 11 },
	context = { triggerKind = 1 },
}, 15_000)

local found_amend = false
for _, result in pairs(commit_response or {}) do
	local items = result.result and (result.result.items or result.result) or {}
	for _, item in ipairs(items) do
		local origin = item.data and item.data.kakehashi and item.data.kakehashi.origin
		if origin == "fish_lsp" and item.label == "--amend" then
			found_amend = true
			break
		end
	end
end

vim.bo.modified = false
if not found_amend then
	vim.api.nvim_err_writeln("Gin commit followed by a space did not reach fish_lsp completion")
	vim.cmd.cquit()
end
