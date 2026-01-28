local M = {
	did_setup_mappings = false,
	augroup = vim.api.nvim_create_augroup("atusy.lsp", {}),
}

--- Cache the current buffer with the attached LSP clients.
function M.cache(bufnr, clients)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	clients = clients or vim.lsp.get_clients({ bufnr = bufnr })
	for _, client in ipairs(clients) do
		if client.name == "denols" then
			local filename = vim.api.nvim_buf_get_name(bufnr)
			if filename ~= "" then
				vim.system({ "deno", "cache", filename }, {}, function() end)
			end
		end
	end
end

--- Delete lsp-default mappings starting with 'gr'
function M.delete_default_mappings()
	for _, m in pairs(vim.api.nvim_get_keymap("n")) do
		if m.lhs and m.lhs:sub(1, 2) == "gr" then
			vim.api.nvim_del_keymap("n", m.lhs)
		end
	end
end

--- Setup buffer-local and global mappings for LSP
function M.setup_mappings(bufnr, client)
	-- mappings (global)
	if not M.did_setup_mappings then
		-- on init
		M.delete_default_mappings()
		M.did_setup_mappings = true

		-- mappigns with builtin APIs
		vim.keymap.set("n", "gD", [[<Cmd>lua vim.lsp.buf.declaration()<CR>]], { silent = true })
		vim.keymap.set("n", "gs", [[<Cmd>lua vim.lsp.buf.signature_help()<CR>]], { silent = true })
		vim.keymap.set("n", "gK", [[<Cmd>lua vim.lsp.buf.type_definition()<CR>]], { silent = true }) -- Kata teigi
		vim.keymap.set("n", "ga", [[<Cmd>lua require('lspsaga.codeaction'):code_action()<CR>]], { silent = true }) -- use :as for original ga
		vim.keymap.set("n", "K", [[<Cmd>lua vim.lsp.buf.hover()<CR>]], { silent = true })
		vim.keymap.set("i", "<C-A>", [[<Cmd>lua vim.lsp.inline_completion.get()<CR>]], { silent = true })
		vim.keymap.set("n", " r", [[<Cmd>lua vim.lsp.buf.rename()<CR>]], { silent = true })

		-- mappings with plugin APIs with fallback
		vim.keymap.set("n", "gd", function()
			local ok, telescope = pcall(require, "telescope.builtin")
			if ok then
				telescope.lsp_definitions()
			else
				vim.lsp.buf.definition()
			end
		end)
		vim.keymap.set("n", "gi", function()
			local ok, telescope = pcall(require, "telescope.builtin")
			if ok then
				telescope.lsp_implementations()
			else
				vim.lsp.buf.implementation()
			end
		end)
		vim.keymap.set("n", "gr", function()
			local ok, telescope = pcall(require, "telescope.builtin")
			if ok then
				telescope.lsp_references()
			else
				vim.lsp.buf.references()
			end
		end)
		vim.keymap.set("n", "gf", function()
			local ok, gtd = pcall(function()
				return require("plugins.telescope.picker").gtd
			end)
			if ok then
				gtd()
			else
				vim.cmd([[normal! gF]])
			end
		end)
	end
end

--- Enable inline completion iff on Insert mode
---
--- To workaround the issue that inline completion stops working at some point.
function M.setup_inline_completion()
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = M.augroup,
		desc = "Enable inline completion just before entering Insert mode",
		callback = function(ctx)
			local opts = { bufnr = ctx.buf }
			if not vim.lsp.inline_completion.is_enabled(opts) then
				vim.lsp.inline_completion.enable(false, opts) -- force restart
			end
			vim.lsp.inline_completion.enable(true, opts)
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = M.augroup,
		desc = "Disable inline completion after leaving Insert mode",
		callback = function(ctx)
			if ctx.match:match("^i:") then
				local opts = { bufnr = ctx.buf }
				vim.lsp.inline_completion.enable(false, opts)
			end
		end,
	})
end

function M.setup()
	vim.lsp.inline_completion.enable(true)
	vim.api.nvim_create_autocmd("FileType", {
		group = M.augroup,
		once = true,
		callback = function()
			pcall(require, "lspconfig")
			vim.lsp.log.set_level(
				vim.env.NVIM_LSP_LOGLEVEL and vim.lsp.log_levels[vim.env.NVIM_LSP_LOGLEVEL] or vim.lsp.log_levels.ERROR
			)
			vim.lsp.linked_editing_range.enable(true)
			vim.lsp.config("*", {
				---@param client vim.lsp.Client
				on_init = function(client)
					-- Disable semantic tokens for all LSPs except kakehashi
					if client.name ~= "kakehashi" then
						client.server_capabilities.semanticTokensProvider = nil
						return
					end

					-- Prefer semanticTokens/full/delta over range (Neovim default) to avoid flikering on scroll
					pcall(function()
						if client.server_capabilities.semanticTokensProvider.full.delta then
							client.server_capabilities.semanticTokensProvider.range = false
						end
					end)
				end,
			})

			-- NOTE: If unscheduled, fails to attach servers to files opened via CLI command (e.g., nvim foo.rs)
			vim.schedule(function()
				vim.lsp.enable({
					"bashls",
					"copilot",
					-- "denols", -- enabled conditionally
					"gopls",
					"html",
					"jsonls",
					"kakehashi",
					"lua_ls",
					"nixd",
					"pyright",
					"r_language_server",
					"rust_analyzer",
					"terraformls",
					-- "ts_ls", -- enabled conditionally
					"yamlls",
				})
			end)
		end,
	})

	vim.api.nvim_create_autocmd("FileType", {
		group = M.augroup,
		callback = function(ctx)
			if ctx.match == "lazy" then
				-- NOTE: Avoid potential errors with lazy.nvim
				-- lazy.nvim may open lazy-filetype buffer on startup before loading plugins
				return
			end

			local filetypes =
				{ "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" }

			-- ts_ls
			if
				vim.tbl_contains(vim.lsp.config.ts_ls.filetypes or filetypes, ctx.match)
				and (function()
					local ok, is_node = pcall(function()
						return require("lspconfig").util.root_pattern("package.json")(ctx.file)
					end)
					if ok then
						return is_node
					end
					return vim.fn.findfile("package.json", ".;") ~= ""
				end)()
			then
				vim.lsp.start(vim.lsp.config.ts_ls, { bufnr = ctx.buf })
				return
			end

			-- denols
			if vim.tbl_contains(vim.lsp.config.denols.filetypes or filetypes, ctx.match) then
				vim.lsp.start(vim.lsp.config.denols, { bufnr = ctx.buf })
				return
			end
		end,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = M.augroup,
		once = false, -- because of buffer-local configurations
		callback = function(ctx)
			local client = vim.lsp.get_client_by_id(ctx.data.client_id)
			if client then
				M.cache(ctx.buf, { client })
				M.setup_mappings(ctx.buf, client)
			end
		end,
	})

	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = M.augroup,
		once = true,
		callback = function()
			vim.diagnostic.config({
				signs = false,
				underline = true,
				virtual_text = true,
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
