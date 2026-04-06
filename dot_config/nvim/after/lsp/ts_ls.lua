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
		local node_root =
			vim.fs.root(bufnr, { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" })
		if not node_root then
			return
		end

		local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
		if deno_lock_root and (#deno_lock_root > #node_root) then
			-- deno lock is closer than package manager lock, abort
			return
		end

		local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
		if deno_root and (#deno_root >= #node_root) then
			-- deno config is closer than or equal to package manager lock, abort
			return
		end

		-- project is standard TS, not deno
		on_dir(node_root)
	end,
}
