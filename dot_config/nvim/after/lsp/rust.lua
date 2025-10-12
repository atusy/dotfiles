---@type vim.lsp.Config
return {
	settings = {
		["rust-analyzer"] = {
			diagnostics = {
				enable = true,
				experimental = {
					enable = true,
				},
			},
		},
	},
}
