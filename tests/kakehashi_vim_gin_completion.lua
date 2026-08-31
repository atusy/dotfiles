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

local function assert_fish_completion(label, message)
	local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]
	local response = vim.lsp.buf_request_sync(0, "textDocument/completion", {
		textDocument = { uri = vim.uri_from_bufnr(0) },
		position = { line = 0, character = #line },
		context = { triggerKind = 1 },
	}, 15_000)

	local found = false
	local observed = {}
	for _, result in pairs(response or {}) do
		local items = result.result and (result.result.items or result.result) or {}
		for _, item in ipairs(items) do
			local origin = item.data and item.data.kakehashi and item.data.kakehashi.origin
			observed[origin or "none"] = (observed[origin or "none"] or 0) + 1
			if origin == "fish_lsp" and item.label == label then
				found = true
				break
			end
		end
	end

	if not found then
		vim.bo.modified = false
		vim.api.nvim_err_writeln(message .. ": " .. vim.inspect(observed))
		vim.cmd.cquit()
	end
end

assert_fish_completion("add", "Gin followed by a space did not reach fish_lsp completion")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "Gin commit " })
assert_fish_completion("--amend", "Gin commit followed by a space did not reach fish_lsp completion")

vim.bo.modified = false
