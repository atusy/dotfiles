local M = {
	loaded = false,
	mappings = {
		object_scope = "<Plug>(MiniIndentscope-ii)",
		object_scope_with_border = "<Plug>(MiniIndentscope-ai)",
		goto_top = "<Plug>(indentscope-goto-top)",
		goto_bottom = "<Plug>(indentscope-goto-bottom)",
	},
}

function M.setup()
	M.loaded = true
	vim.g.miniindentscope_disable = true
	require("mini.indentscope").setup({
		mappings = M.mappings,
		symbol = "╎",
	})
end

function M.set_keymaps()
	local plug_lazy = "<Plug>(mini.indentscope-lazy)"
	vim.keymap.set({ "n", "x", "o" }, plug_lazy, function()
		if not M.loaded then
			M.setup()
		end
	end)
	vim.keymap.set({ "n" }, "<bar>", function()
		if not M.loaded then
			M.setup()
		end
		if vim.v.count > 0 then
			vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], vim.v.count - 1 })
			return
		end
		M.toggle()
	end)
	vim.keymap.set({ "x", "o" }, "i<tab>", plug_lazy .. M.mappings.object_scope)
	vim.keymap.set({ "x", "o" }, "a<tab>", plug_lazy .. M.mappings.object_scope_with_border)
	vim.keymap.set({ "n", "x", "o" }, "[<tab>", plug_lazy .. M.mappings.goto_top)
	vim.keymap.set({ "n", "x", "o" }, "]<tab>", plug_lazy .. M.mappings.goto_bottom)
end

function M.disable()
	vim.g.miniindentscope_disable = true
	require("mini.indentscope").undraw()
end

function M.enable()
	vim.g.miniindentscope_disable = false
	require("mini.indentscope").draw()
end

function M.toggle()
	if vim.g.miniindentscope_disable then
		M.enable()
	else
		M.disable()
	end
end

function M.lazy()
	M.set_keymaps()
end

return M
