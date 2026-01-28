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
return { single_file_support = true }
