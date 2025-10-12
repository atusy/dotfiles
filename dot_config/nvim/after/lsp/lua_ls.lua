---@type vim.lsp.Config
return {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim", "pandoc" } },
			workspace = {
				library = { vim.env.VIMRUNTIME },
				checkThirdParty = false,
			},
			format = { enable = false },
			semantic = { enable = false },
		},
	},
}
