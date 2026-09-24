-- laser presentation and lifecycle around skkelua's shared completion API.
local M = {}

function M.item(item)
	local laser = vim.tbl_get(item, "user_data", "laser")
	if laser then
		return laser.item or {}
	end
	return {}
end

function M.on_complete_done(item)
	require("skkelua.completion").accept(M.item(item))
end

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

---Confirm laser's selection and let skkelua learn from it.
---laser fires no event on confirmation, so acceptance follows the call instead.
---@return boolean confirmed
function M.confirm()
	local candidate = selected()
	local confirmed = require("laser").confirm()
	if confirmed and candidate then
		M.on_complete_done(candidate)
	end
	return confirmed
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

local fed_backspace_allowed = false

---Let fed <BS> replace the pre-edit while skkelua's guard is active.
---laser types candidates as <BS> and text, but the guard treats any <BS> as a
---physical key. Remove once skkelua's guard passes fed keys by itself.
---Call before skkelua's first enable, which registers the guard's callback.
function M.allow_fed_backspace()
	if fed_backspace_allowed then
		return
	end
	fed_backspace_allowed = true
	local guard = require("skkelua.guard")
	local on_key = guard._on_key
	local bs = vim.keycode("<BS>")
	guard._on_key = function(key, typed)
		-- Macros replay keys untyped too; keep guarding them.
		if key == bs and typed == "" and vim.fn.reg_executing() == "" then
			return
		end
		return on_key(key, typed)
	end
end

function M.setup(opts)
	opts = opts or {}
	require("skkelua.completion").set_adapter({
		state = function()
			local candidate = selected()
			return {
				visible = require("laser").visible(),
				-- Selecting inserts the word unless it would split the line;
				-- skkelua checks the text before the cursor for it anyway.
				selected = candidate and { word = candidate.word, item = M.item(candidate) } or nil,
			}
		end,
		confirm = function()
			return vim.keycode("<Cmd>lua require('atusy.lsp.skkelua').confirm()<CR>")
		end,
		trigger = function()
			if opts.trigger then
				opts.trigger()
			else
				require("plugins.laser.completion").complete()
			end
		end,
	})
	local group = vim.api.nvim_create_augroup("atusy.skkelua.lsp", { clear = true })
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
