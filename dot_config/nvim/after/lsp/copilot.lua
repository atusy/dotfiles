local prev_buf = nil

local function notify_did_focus(client, bufnr)
	if prev_buf == bufnr or not client or client.initialized == false or not client.attached_buffers[bufnr] then
		return
	end
	---@diagnostic disable-next-line: param-type-mismatch
	client:notify("textDocument/didFocus", { textDocument = { uri = vim.uri_from_bufnr(bufnr) } })
	prev_buf = bufnr
end

vim.api.nvim_create_autocmd("LspAttach", {
	---@return boolean
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "copilot" then
			return false
		end

		notify_did_focus(client, vim.api.nvim_get_current_buf())

		vim.api.nvim_create_autocmd({
			"BufWinEnter", -- when changing buffer in window
			"WinEnter", -- when changing window
		}, {
			callback = function()
				local bufnr = vim.api.nvim_get_current_buf()
				local client = vim.lsp.get_clients({ bufnr = bufnr, name = "copilot" })[1]
				notify_did_focus(client, bufnr)
			end,
		})

		return true
	end,
})

return {}
