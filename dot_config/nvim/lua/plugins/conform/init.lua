return {
	{
		"https://github.com/stevearc/conform.nvim",
		lazy = true,
		event = "BufWritePre", -- "BufWriteCmd"
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- format with gq{motion}
			vim.keymap.set({ "n", "x" }, "gqq", function()
				-- for original gqq, use gqgq
				require("conform").format({ async = true, lsp_format = "fallback" })
			end)
		end,
		config = function()
			require("conform").setup({
				default_format_opts = {
					lsp_format = "fallback",
					timeout_ms = 500,
				},
				format_on_save = function(buf)
					if vim.v.cmdbang == 1 then
						return nil
					end

					local name = vim.api.nvim_buf_get_name(buf)
					local basename = vim.fs.basename(name)

					if basename:match("%.lock$") or basename:match("%plock%p") then
						-- do not format lock files
						return nil
					end

					return {}
				end,
			})
		end,
	},
}
