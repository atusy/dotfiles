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

		notify_did_focus(client, ev.buf)

		vim.api.nvim_create_autocmd({
			"BufWinEnter", -- when changing buffer in window
			"WinEnter", -- when changing window
		}, {
			callback = function(ev2)
				notify_did_focus(client, ev2.buf)
			end,
			group = vim.api.nvim_create_augroup("atusy-copilot-did-focus", { clear = true }),
		})

		return true
	end,
})

return vim.empty_dict()
