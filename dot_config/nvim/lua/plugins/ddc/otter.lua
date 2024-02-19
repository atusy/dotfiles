local function setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "quarto",
		callback = function(ctx)
			vim.fn["ddc#custom#set_context_filetype"]("quarto", function()
				-- test if otter is available
				local ok, otter_keeper = pcall(require, "otter.keeper")
				if not ok then
					return {}
				end

				-- sync quarto buffer with otter buffers
				otter_keeper.sync_raft(ctx.buf)

				-- conditional sourceParams for ddc-source-lsp based on the cursor positions
				local cursor = vim.api.nvim_win_get_cursor(0)
				local otter_attached = otter_keeper._otters_attached[ctx.buf]
				for _, chunks in pairs(otter_attached.code_chunks) do
					for _, chunk in pairs(chunks) do
						local srow, scol = chunk.range.from[1] + 1, chunk.range.from[2]
						local erow, ecol = chunk.range.to[1] + 1, chunk.range.to[2]
						if
							((cursor[1] == srow and cursor[2] >= scol) or (cursor[1] > srow))
							and ((cursor[1] == erow and cursor[2] <= ecol) or cursor[1] < erow)
						then
							return {
								sourceParams = {
									lsp = {
										bufnr = otter_attached.buffers[chunk.lang],
										enableResolveItem = true,
										enableAdditionalTextEdit = true,
										confirmBehavior = "replace",
									},
								},
							}
						end
					end
				end

				-- if current cursor is not inside a chunk, do nothing
				return {}
			end)
		end,
	})
end

return setup
