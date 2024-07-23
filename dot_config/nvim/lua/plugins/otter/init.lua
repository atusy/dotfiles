local languages = { "r", "python", "bash", "lua", "html", "javascript", "typescript" }

local function ddc_custom_context(ctx)
	-- test if otter is available
	local ok, otter_keeper = pcall(require, "otter.keeper")
	if not ok then
		return {}
	end

	-- sync quarto buffer with otter buffers
	ok = pcall(otter_keeper.sync_raft, ctx.buf)
	if not ok then
		pcall(require("otter").activate, languages, false, false)
		ok = pcall(otter_keeper.sync_raft, ctx.buf)
		if not ok then
			return {}
		end
	end

	-- conditional sourceParams for ddc-source-lsp based on the cursor positions
	local cursor = vim.api.nvim_win_get_cursor(0)
	local otter_attached = otter_keeper._otters_attached[ctx.buf]
	if not otter_attached then
		return {}
	end
	for _, chunks in pairs(otter_attached.code_chunks) do
		for _, chunk in pairs(chunks) do
			local srow, scol = chunk.range.from[1] + 1, chunk.range.from[2]
			local erow, ecol = chunk.range.to[1] + 1, chunk.range.to[2]
			if
				((cursor[1] == srow and cursor[2] >= scol) or (cursor[1] > srow))
				and ((cursor[1] == erow and cursor[2] <= ecol) or cursor[1] < erow)
			then
				local bufnr = otter_attached.buffers[chunk.lang]
				return { sourceParams = { lsp = { bufnr = bufnr } } }
			end
		end
	end

	-- if current cursor is not inside a chunk, do nothing
	return {}
end

return {
	{
		"https://github.com/jmbuhr/otter.nvim",
		lazy = true,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "markdown", "quarto" },
				callback = function(ctx)
					if ctx.match == "markdown" then
						pcall(require("otter").activate, languages, false, false)
					end
					for lhs, rhs in pairs({
						-- gS = ":lua require'otter'.ask_document_symbols()<cr>",
						-- gd = ":lua require'otter'.ask_definition()<cr>",
						K = "<cmd>lua vim.lsp.buf.hover()<cr>",
						-- gr = ":lua require'otter'.ask_references()<cr>",
						-- [" r"] = ":lua require'otter'.ask_rename()<cr>",
						-- [" lf"] = ":lua require'otter'.ask_format()<cr>",
						-- [" lt"] = ":lua require'otter'.ask_type_definition()<cr>",
					}) do
						vim.keymap.set("n", lhs, rhs, { silent = true, buffer = true })
					end
					vim.fn["ddc#custom#set_context_filetype"](ctx.match, function()
						return ddc_custom_context(ctx)
					end)
				end,
			})
		end,
	},
}
