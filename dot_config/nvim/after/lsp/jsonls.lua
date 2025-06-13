local ok, schemastore = pcall(require, "schemastore")
vim.lsp.config.jsonls = {
	settings = {
		json = {
			schemas = ok and schemastore.json.schemas() or nil,
			validate = { enable = true },
		},
	},
}
