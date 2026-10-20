-- laser presentation and lifecycle around skkelua's completion adapter.
local M = {}

---@return table? candidate selected in laser's menu
local function selected()
	local laser = require("laser")
	if not laser.visible() then
		return nil
	end
	-- laser has no public accessor for its selection yet.
	local ui = laser._engine().ui
	return ui.items()[ui.selected()]
end

---Keys for SKK's <C-g>: restore a selected candidate's reading first, and
---otherwise close the menu and cancel the conversion on the same key press.
---@return string
function M.cancel_keys()
	local laser_cancel = "<Cmd>lua require('laser').cancel()<CR>"
	local skk_cancel = "<Cmd>lua require('skkelua').handle('handleKey', { key = '<C-g>' })<CR>"
	if not require("laser").visible() then
		return skk_cancel
	end
	if selected() then
		return laser_cancel
	end
	return laser_cancel .. skk_cancel
end

function M.setup(opts)
	opts = opts or {}
	require("skkelua.completion").set_adapter({
		selected = function()
			local candidate = selected()
			if not candidate then
				return nil
			end
			local laser = vim.tbl_get(candidate, "user_data", "laser")
			return laser and laser.item or {}
		end,
		confirm = function()
			return vim.keycode("<Cmd>lua require('laser').confirm()<CR>")
		end,
	})
	local group = vim.api.nvim_create_augroup("atusy.skkelua.laser", { clear = true })
	-- Restoring the pre-edit involves no typing, so laser does not complete by itself.
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "skkelua-pre-edit-restored",
		callback = function()
			if opts.trigger then
				opts.trigger()
			else
				require("plugins.laser.completion").complete()
			end
		end,
	})
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
