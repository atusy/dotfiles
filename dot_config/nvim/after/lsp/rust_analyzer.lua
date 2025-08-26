vim.lsp.config.rust_analyzer = {
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
