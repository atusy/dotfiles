local home = vim.uv.os_homedir()
if not home then
	return
end

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Prefer LSP semantic tokens over Treesitter for kakehashi",
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "kakehashi" then
			return
		end

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
	on_init = function(client)
		-- to use semanticTokens/full/delta
		client.server_capabilities.semanticTokensProvider.range = false
	end,
}
