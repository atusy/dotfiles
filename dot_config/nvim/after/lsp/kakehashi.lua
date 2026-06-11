local home = vim.uv.os_homedir()
if not home then
	return
end

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "kakehashi setup per buffer",
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "kakehashi" then
			return
		end

		-- Prefer LSP semantic tokens over Treesitter for kakehashi
		vim.api.nvim_create_autocmd("LspTokenUpdate", {
			buffer = ev.buf,
			once = true,
			callback = function()
				vim.opt_local.syntax = "OFF"
				vim.treesitter.stop()
			end,
		})
	end,
})

---@type vim.lsp.Config
return {
	cmd = { vim.fs.joinpath(home, ".cargo/bin/kakehashi") },
	root_dir = function(bufnr, on_dir)
		-- skip terminal buffers (e.g., toggleterm)
		if vim.bo[bufnr].buftype == "terminal" then
			return
		end
		if vim.bo[bufnr].filetype == "gin-buffer" then
			return
		end
		on_dir()
	end,
	on_init = function(client)
		-- to use semanticTokens/full/delta
		client.server_capabilities.semanticTokensProvider.range = false
	end,
}
