-- Completion/pum presentation and lifecycle around skkelua's shared completion API.
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

function M.setup(opts)
	opts = opts or {}
	require("skkelua.completion").set_adapter({
		state = function()
			local info = vim.fn["pum#complete_info"]()
			local selected = (info.selected or -1) >= 0 and info.items[info.selected + 1]
			return {
				visible = info.pum_visible == true or info.pum_visible == 1,
				selected = selected and { word = info.inserted or "", item = M.item(selected) } or nil,
			}
		end,
		confirm = function()
			return vim.keycode("<Cmd>call pum#map#confirm()<CR>")
		end,
		trigger = function()
			if opts.trigger then
				opts.trigger()
			else
				require("plugins.laser").complete()
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
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "PumCompleteDone",
		callback = function()
			if vim.g["pum#completed_event"] == "confirm" then
				M.on_complete_done(vim.g["pum#completed_item"] or {})
			end
		end,
	})
end

return M
