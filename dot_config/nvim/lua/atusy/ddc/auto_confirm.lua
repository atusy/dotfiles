--- Confirm the selected pum.vim candidate when typing continues.
---
--- Selecting with pum#map#insert_relative() only inserts the candidate's word;
--- LSP-side effects (textEdit expansion such as emoji shortcodes, and
--- additionalTextEdits) are applied by ddc's onCompleteDone, which normally
--- fires asynchronously and bails out once the typed character has changed the
--- line. Intercepting InsertCharPre lets us confirm synchronously first and
--- re-feed the character afterwards, so continuing to type behaves like <C-Y>.
local M = {}

--- The candidate captured on InsertCharPre. It must be captured there because
--- pum.vim's own InsertCharPre handler (s:check_user_input) closes the popup
--- and discards the selection before the re-fed <Cmd> below gets to run.
local pending = nil

local function selected_item()
	if not vim.fn["pum#visible"]() then
		return nil
	end
	local info = vim.fn["pum#complete_info"]()
	if info.selected < 0 or info.inserted == "" then
		return nil
	end
	return vim.fn["pum#current_item"]()
end

--- Runs via <Cmd> (outside textlock) before the suppressed char is re-inserted.
function M.confirm()
	local item = pending
	pending = nil
	if not item then
		return
	end
	if vim.fn["pum#visible"]() then
		vim.fn["pum#map#confirm"]()
	end
	-- pum#close() publishes v:completed_item on a timer, which is too late for
	-- the synchronous request below; ddc-source-nvim-lsp reads it to decide
	-- whether the buffer still matches the confirmed word.
	vim.v.completed_item = item
	pcall(vim.fn["denops#request"], "ddc", "onCompleteDone", { item })
	-- This path suppresses PumCompleteDone, so forward SKK learning explicitly.
	local skk = package.loaded["atusy.lsp.skkelua"]
	if skk then
		skk.on_complete_done(item)
	end
end

function M.setup()
	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = vim.api.nvim_create_augroup("atusy.ddc.auto_confirm", {}),
		callback = function()
			local item = selected_item()
			if not item then
				return
			end
			pending = item
			-- pum.vim's own InsertCharPre handler runs next and calls pum#close(),
			-- which schedules a deferred complete-done for the still-active
			-- candidate. That event would notify ddc's onCompleteDone a second
			-- time and race the synchronous confirm below inside denops, with
			-- both passing the buffer-text guard on the same pre-edit snapshot
			-- and double-applying the textEdit (LSPRangeError). Clearing the
			-- candidate state here makes that close a plain window close;
			-- pum#popup#_close() performs the same reset itself.
			vim.cmd([[call extend(pum#_get(), #{cursor: -1, current_word: ''})]])
			local char = vim.v.char
			vim.v.char = ""
			vim.api.nvim_feedkeys(
				vim.keycode("<Cmd>lua require('atusy.ddc.auto_confirm').confirm()<CR>") .. char,
				"in",
				false
			)
		end,
	})
end

return M
