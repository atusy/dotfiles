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

vim.api.nvim_create_autocmd("LspAttach", {
	desc = "Configure kakehashi with the list of enabled language servers",
	once = true,
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if not client or client.name ~= "kakehashi" then
			return
		end

		---@diagnostic disable-next-line: param-type-mismatch
		client:request("kakehashi/internal/effectiveConfiguration", vim.empty_dict(), function(err, result)
			local settings = (not err and result and result.settings) or {}
			local language_servers = settings.languageServers or {}
			local ignored_servers = { copilot = true, kakehashi = true, denols = true }
			for name, enabled_config in pairs(vim.lsp._enabled_configs) do
				if not ignored_servers[name] ~= false then
					language_servers[name] = vim.tbl_extend("force", {
						cmd = enabled_config.resolved_config.cmd,
						languages = enabled_config.resolved_config.filetypes,
					}, language_servers[name] or {})
				end
			end
			client:notify("workspace/didChangeConfiguration", {
				settings = { languageServers = language_servers },
			})
		end)
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
