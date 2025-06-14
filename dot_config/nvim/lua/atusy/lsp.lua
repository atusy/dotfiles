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

	-- caching and mappings
	local global_mappings = false
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

			-- mappings (global)
			if not global_mappings then
				global_mappings = true
				-- delete lsp-default mappings starting with 'gr'
				for _, m in pairs(vim.api.nvim_get_keymap("n")) do
					if m.lhs and m.lhs:match("^gr") then
						vim.api.nvim_del_keymap("n", m.lhs)
					end
				end

				-- set global mappings
				local function nmap(lhs, rhs)
					vim.keymap.set("n", lhs, rhs, { silent = true })
				end
				local ok, telescope = pcall(require, "telescope.builtin")
				if ok then
					nmap("gd", telescope.lsp_definitions)
					nmap("gi", telescope.lsp_implementations)
					nmap("gr", telescope.lsp_references)
					nmap("gf", [[<Cmd>lua require("plugins.telescope.picker").gtd()<CR>]])
				else
					nmap("gd", [[<Cmd>lua vim.lsp.buf.definition()<CR>]])
					nmap("gi", [[<Cmd>lua vim.lsp.buf.implementation()<CR>]])
					nmap("gr", [[<Cmd>lua vim.lsp.buf.references()<CR>]])
				end
				nmap("gD", [[<Cmd>lua vim.lsp.buf.declaration()<CR>]])
				nmap("gs", [[<Cmd>lua vim.lsp.buf.signature_help()<CR>]])
				nmap("gK", [[<Cmd>lua vim.lsp.buf.type_definition()<CR>]]) -- Kata teigi
				nmap("ga", [[<Cmd>lua require('lspsaga.codeaction'):code_action()<CR>]]) -- use :as for original ga
			end

			-- mappings (buffer-local)
			if client.server_capabilities.renameProvider then
				vim.keymap.set("n", " r", [[<Cmd>lua vim.lsp.buf.rename()<CR>]], { silent = true, buffer = bufnr })
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
