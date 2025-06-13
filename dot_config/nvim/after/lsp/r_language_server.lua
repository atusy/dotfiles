vim.lsp.config.r_language_server = {
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
