---@type vim.lsp.Config
return {
	root_dir = function(bufnr, on_dir)
		vim.lsp.config.ts_ls.root_dir(bufnr, on_dir)
	end,
}
