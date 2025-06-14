local M = {
	did_setup_mappings = false,
}

local augroup = vim.api.nvim_create_augroup("atusy.lsp", {})

local function has_node_modules()
	return vim.fn.isdirectory("node_modules") == 1 or vim.fn.findfile("package.json", ".;") ~= ""
end

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
		if m.lhs and m.lhs:match("^gr") then
			vim.api.nvim_del_keymap("n", m.lhs)
		end
	end
end

--- Setup buffer-local and global mappings for LSP
function M.setup_mappings(bufnr, client)
	-- mappings (buffer-local)
	if client.server_capabilities.renameProvider then
		vim.keymap.set("n", " r", [[<Cmd>lua vim.lsp.buf.rename()<CR>]], { silent = true, buffer = bufnr })
	end

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

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		once = true,
		callback = function()
			pcall(require, "lspconfig")
			vim.lsp.set_log_level(vim.lsp.log_levels.OFF)
			vim.lsp.enable({
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
			})
		end,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = augroup,
		callback = function(ctx)
			local client = vim.lsp.get_client_by_id(ctx.data.client_id)
			if client then
				M.cache(ctx.buf, { client })
				M.setup_mappings(ctx.buf, client)
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
