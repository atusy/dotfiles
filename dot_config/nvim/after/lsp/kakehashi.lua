local home = vim.uv.os_homedir()
if not home then
	return
end

---@type vim.lsp.Config
return {
	cmd = { vim.fs.joinpath(home, ".cargo/bin/kakehashi") },
	root_dir = function(bufnr, on_dir)
		-- skip terminal buffers (e.g., toggleterm)
		if vim.bo[bufnr].buftype == "terminal" then
			return
		end
		local ft = vim.bo[bufnr].filetype
		if ft == "gin-buffer" or ft == "toggleterm" then
			return
		end
		on_dir()
	end,
	on_init = function(client)
		-- to use semanticTokens/full/delta
		client.server_capabilities.semanticTokensProvider.range = false
	end,
	on_attach = function(_, bufnr)
		vim.api.nvim_create_autocmd("LspTokenUpdate", {
			buffer = bufnr,
			once = true,
			callback = function()
				vim.opt_local.syntax = "OFF"
				vim.treesitter.stop(bufnr)
			end,
		})
	end,
}
