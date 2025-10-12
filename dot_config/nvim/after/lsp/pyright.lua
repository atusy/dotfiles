---@type vim.lsp.Config
return {
	settings = {
		python = {
			venvPath = ".",
			pythonPath = "./.venv/bin/python",
			analysis = {
				extraPaths = { "." },
			},
			exclude = { "./.worktree" },
		},
	},
}
