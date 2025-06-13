local ok, schemastore = pcall(require, "schemastore")
vim.lsp.config.yamlls = {
	settings = {
		yaml = {
			schemaStore = { enable = false, url = "" },
			schemas = ok and schemastore.json.schemas() or nil,
		},
	},
}
