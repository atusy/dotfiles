---@type vim.lsp.Config
return {
	settings = {
		r = {
			lsp = {
				rich_documentation = false,
			},
		},
	},
	capabilities = {
		textDocument = {
			documentColor = false,
		},
	},
}
