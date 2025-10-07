---@type table<string, table<string, string>>
local lsp_root_dir = {}

---@param client vim.lsp.Client
---@param bufnr integer
local function register_root_dir(client, bufnr)
	if not lsp_root_dir[client.name] then
		lsp_root_dir[client.name] = {}
	end
	if client.root_dir then
		if type(client.root_dir) == "string" then
			lsp_root_dir[client.name][bufnr] = client.root_dir
		elseif type(client.config.root_dir) == "string" then
			lsp_root_dir[client.name][bufnr] = client.config.root_dir
		elseif type(client.config.root_dir) == "function" then
			-- register iff root_dir is not (yet) registered by `client.root_dir()`
			client.config.root_dir(bufnr, function(x)
				if x and not lsp_root_dir[client.name][bufnr] then
					lsp_root_dir[client.name][bufnr] = x
				end
			end)
		end

		if type(client.root_dir) == "function" then
			-- prioritize client.root_dir() to client.config.root_dir()
			-- by registering root dir regardless of the result of client.config.root_dir()
			client.root_dir(bufnr, function(x)
				if x then
					lsp_root_dir[client.name][bufnr] = x
				end
			end)
		end
	end
end

local augroup = vim.api.nvim_create_augroup("atusy-conform", {})
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup,
	callback = function(ctx)
		local client = vim.lsp.get_client_by_id(ctx.data.client_id)
		if not client then
			return
		end
		register_root_dir(client, ctx.buf)
	end,
})

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
		if client.name == "ts_ls" then
			local root_dir = lsp_root_dir["ts_ls"][buf]
			if root_dir then
				project_dir = root_dir
				break
			end
		end
	end

	-- use prettier if package.json contains prettier as a dependency
	local package_json = vim.fs.joinpath(project_dir, "package.json")
	if vim.fn.filereadable(package_json) == 1 then
		local package = vim.fn.json_decode(vim.fn.readfile(package_json))
		if package and package.devDependencies and package.devDependencies.prettier then
			vim.system({ "prettierd", "start" }, {}, function() end) -- to avoid cold start
			return { "prettierd" }
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
