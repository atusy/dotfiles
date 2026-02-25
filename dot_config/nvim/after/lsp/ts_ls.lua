---@type vim.lsp.Config
return {
	--- ts_ls root_dir modified after nvim-lspconfig
	---
	--- Differences:
	--- 1. no `.git` as root_marker
	--- 2. do not attach when project_root is not found
	---
	--- Apache License Version 2.0 https://github.com/neovim/nvim-lspconfig
	root_dir = function(bufnr, on_dir)
		local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
		-- exclude deno
		local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
		local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
		local project_root = vim.fs.root(bufnr, root_markers)
		if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
			-- deno lock is closer than package manager lock, abort
			return
		end
		if deno_root and (not project_root or #deno_root >= #project_root) then
			-- deno config is closer than or equal to package manager lock, abort
			return
		end
		-- project is standard TS, not deno
		on_dir(project_root)
	end,
}
