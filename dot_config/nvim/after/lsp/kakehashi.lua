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

		local language_servers = {}
		for name, enabled_config in pairs(vim.lsp._enabled_configs) do
			if enabled_config.resolved_config.filetypes and ({ copilot = false, kakehashi = false })[name] ~= false then
				language_servers[name] = vim.tbl_extend("force", {
					cmd = enabled_config.resolved_config.cmd,
					languages = enabled_config.resolved_config.filetypes,
				}, language_servers[name] or {})
			end
		end
		client:notify("workspace/didChangeConfiguration", {
			settings = { languageServers = language_servers },
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
