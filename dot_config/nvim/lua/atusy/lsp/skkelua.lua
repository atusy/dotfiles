-- ddc/pum presentation and lifecycle around skkelua's shared completion API.
local M = {}

function M.item(item)
	if item.__sourceName ~= "skkelua" and item.__sourceName ~= "skkelua-cmdline" then
		return {}
	end
	local value = vim.tbl_get(item, "user_data", "lspitem")
	return value and vim.json.decode(value) or {}
end

function M.on_complete_done(item)
	require("skkelua.completion").accept(M.item(item))
end

-- Resolve ddc-source-nvim-lsp's document representation against the active input.
function M.get_context(params)
	local lsp = require("skkelua.lsp")
	local mode = vim.fn.mode():sub(1, 1)
	if mode == "i" then
		if params.textDocument.uri == vim.uri_from_bufnr(0) then
			return lsp.get_context(params, 0)
		end
	elseif mode == "c" then
		local context, buf = lsp.get_context(params)
		if
			context
			and vim.bo[buf].filetype == "ddc_skkelua"
			and vim.bo[buf].buftype == "nofile"
			and context.row == 0
			and context.line == vim.fn.getcmdline()
			and context.col == vim.fn.getcmdpos() - 1
		then
			return context
		end
	end
end

function M.setup()
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
			-- Preserve inline source options (in particular the empty SKK filters).
			vim.fn["ddc#map#manual_complete"]()
		end,
	})
	local group = vim.api.nvim_create_augroup("atusy.skkelua.lsp", { clear = true })
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			if vim.fn.mode():sub(1, 1) ~= "c" then
				require("skkelua.lsp").start(nil, M.get_context)
			end
		end,
	})
	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = "ddc_skkelua",
		callback = function(args)
			require("skkelua.lsp").start(args.buf, M.get_context)
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
