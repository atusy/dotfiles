-- laser presentation and lifecycle around skkelua's in-process LSP server.
local M = {}

---Keys for SKK's <C-g>: restore a selected candidate's reading first, and
---otherwise close the menu and cancel the conversion on the same key press.
---@return string
function M.cancel_keys()
	local laser_cancel = "<Cmd>lua require('laser').cancel()<CR>"
	local skk_cancel = "<Cmd>lua require('skkelua').handle('handleKey', { key = '<C-g>' })<CR>"
	if not require("laser").visible() then
		return skk_cancel
	end
	if require("laser").get_selected() then
		return laser_cancel
	end
	return laser_cancel .. skk_cancel
end

function M.setup()
	local group = vim.api.nvim_create_augroup("atusy.skkelua.laser", { clear = true })
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			if vim.fn.mode():sub(1, 1) ~= "c" then
				require("skkelua.lsp").start()
			end
		end,
	})
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "*",
		callback = function(args)
			if vim.api.nvim_buf_get_name(args.buf):match("^untitled://laser%-cmdline/") then
				require("skkelua.lsp").start(args.buf)
			end
		end,
	})
end

return M
