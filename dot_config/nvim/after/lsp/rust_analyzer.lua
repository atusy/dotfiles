---@type vim.lsp.Config
return {
	settings = {
		["rust-analyzer"] = {
			cargo = {
				buildScripts = { enable = true },
				features = "all",
				imports = { granularity = { enforce = true } },
			},
			diagnostics = {
				enable = true,
				experimental = {
					enable = true,
				},
			},
		},
	},
}
