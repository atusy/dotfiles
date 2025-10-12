local ok, schemastore = pcall(require, "schemastore")

---@type vim.lsp.Config
return {
	settings = {
		yaml = {
			schemaStore = { enable = false, url = "" },
			schemas = ok and schemastore.json.schemas() or nil,
		},
	},
}
