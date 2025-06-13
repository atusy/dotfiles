vim.lsp.config.pyright = {
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
