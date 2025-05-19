local function make_formatter_ts(buf)
	local biome = {
		"biome-organize-imports",
		"biome-check",
		"biome",
	}

	local project_dir = vim.fn.getcwd()
	local lsp_clients = vim.lsp.get_clients({ bufnr = buf })

	for _, client in ipairs(lsp_clients) do
		if client.name == "denols" then
			return { lsp_format = "prefer" }
		end
		if client.name == "tsserver" then
			project_dir = client.config.root_dir
			break
		end
	end

	-- use prettier if package.json contains prettier as a dependency
	-- XXX: use biome anyway as prettier is too slow
	local package_json = vim.fs.joinpath(project_dir, "package.json")
	if vim.fn.filereadable(package_json) == 1 then
		local package = vim.fn.json_decode(vim.fn.readfile(package_json))
		if package and package.devDependencies and package.devDependencies.prettier then
			-- return { "prettier" }
			return biome
		end
	end

	-- otherwise, use biome
	return biome
end

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
					local name = vim.api.nvim_buf_get_name(buf)
					local basename = vim.fs.basename(name)

					if basename:match("%.lock$") or basename:match("%plock%p") then
						-- do not format lock files
						return nil
					end

					return {}
				end,
				formatters_by_ft = {
					go = { "goimports", lsp_format = "last" }, -- to use gofumpt via LSP
					javascript = make_formatter_ts,
					lua = { "stylua" },
					typescript = make_formatter_ts,
					typescriptreact = make_formatter_ts,
					nix = { "nixfmt" },
					python = { "ruff_format", "ruff_fix" },
					r = { "air", "styler", stop_after_first = true },
					rmd = { "air", "styler", stop_after_first = true },
				},
			})
		end,
	},
}
