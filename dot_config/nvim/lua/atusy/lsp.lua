local M = {}

local augroup = vim.api.nvim_create_augroup("atusy.lsp", {})

local function has_node_modules()
	return vim.fn.isdirectory("node_modules") == 1 or vim.fn.findfile("package.json", ".;") ~= ""
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		callback = function(ctx)
			pcall(require, "lspconfig")
			local filetype = ctx.match

			-- List of available LSP servers
			local servers = {
				"bashls",
				"gopls",
				"jsonls",
				"lua_ls",
				"pyright",
				"r_language_server",
				"nixd",
				"terraformls",
				"yamlls",
				has_node_modules() and "ts_ls" or "denols",
			}

			vim.lsp.set_log_level(vim.lsp.log_levels.OFF)
			vim.lsp.enable(servers) -- enable them for the next time

			-- Check each server to see if it supports the current filetype
			for _, server_name in ipairs(servers) do
				local config = vim.lsp.config[server_name]
				for _, ft in ipairs(config and config.filetypes or {}) do
					if ft == filetype then
						vim.lsp.start(config, { bufnr = ctx.buf })
					end
				end
			end

			-- delay to avoid racing conditions on loading multiple buffers at the same time
			vim.schedule(function()
				pcall(vim.api.nvim_del_autocmd, ctx.id)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = augroup,
		callback = function(ctx)
			local bufnr = ctx.buf
			local client = vim.lsp.get_client_by_id(ctx.data.client_id)
			if not client then
				return
			end

			-- asynchronous cache
			if client.name == "denols" then
				vim.system({ "deno", "cache", vim.api.nvim_buf_get_name(bufnr) }, {}, function() end)
			end
		end,
	})

	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = augroup,
		once = true,
		callback = function()
			vim.diagnostic.config({
				signs = false,
				jump = {
					severity = {
						vim.diagnostic.severity.INFO,
						vim.diagnostic.severity.WARN,
						vim.diagnostic.severity.ERROR,
					},
				},
			})
		end,
	})
end

return M
