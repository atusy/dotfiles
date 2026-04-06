vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Denols: Deno cache on file open",
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "denols" then
			return
		end

		local filename = vim.api.nvim_buf_get_name(ev.buf)
		if vim.uv.fs_stat(filename) then
			vim.system({ "deno", "cache", filename }, {}, function() end)
		end
	end,
})

---@type vim.lsp.Config
return {
	single_file_support = true,
	root_dir = function(bufnr, on_dir)
		local node_root =
			vim.fs.root(bufnr, { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" })
		local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
		local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })

		local len_node_root = node_root and #node_root or 0
		local len_deno_lock_root = deno_lock_root and #deno_lock_root or 0
		local len_deno_root = deno_root and #deno_root or 0

		if len_node_root == 0 or (len_deno_lock_root > len_node_root) or (len_deno_root > len_node_root) then
			on_dir(deno_lock_root or deno_root)
			return
		end
	end,
}
