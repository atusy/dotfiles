--- open or focus the hover
---@param opts? { bufnr?: integer, pos?: {[1]: integer, [2]: integer}, relative?: string, providers?: string[] }
local function hover(opts)
	if vim.b.hover_preview and vim.api.nvim_win_is_valid(vim.b.hover_preview) then
		vim.api.nvim_set_current_win(vim.b.hover_preview)
	else
		require("hover").open(vim.tbl_extend("keep", opts or {}, { providers = { "hover.providers.lsp" } }))
	end
end

return {
	{
		"https://github.com/lewis6991/hover.nvim/",
		lazy = true,
		init = function()
			-- LSP with fallbacks...
			local lhs = "K"
			vim.keymap.set("n", lhs, hover)
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ctx)
					local rhs
					if vim.tbl_contains({ "sh", "bash", "fish", "xonsh", "zsh" }, ctx.match) then
						rhs = function()
							hover({
								providers = {
									"hover.providers.lsp",
									"hover.providers.man",
									"plugins.hover.providers.cmdhelp",
								},
							})
						end
					elseif ctx.match == "man" then
						rhs = "K"
					end
					if rhs then
						vim.keymap.set("n", lhs, rhs, { buffer = ctx.buf })
					end
				end,
			})

			-- gm for get meaning
			vim.keymap.set("n", "gm", function()
				hover({ providers = { "hover.providers.dictionary" } })
			end)
		end,
		config = function()
			require("hover").config({
				providers = {
					"hover.providers.lsp",
					"hover.providers.man",
					"hover.providers.dictionary",
				},
				preview_opts = {
					border = "single",
				},
				preview_window = false,
				title = false,
				mouse_providers = {},
			})
		end,
	},
}
