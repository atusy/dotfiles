local M = {
	did_setup_mappings = false,
	augroup = vim.api.nvim_create_augroup("atusy.lsp", {}),
}

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

--- Start kakehashi during setup
---
--- * to warmup downstream servers for a specific filetype
--- * to attach buffers excluded by builtin attach logic
function M.start_kakehashi(filetype)
	-- warmup
	local buf = vim.api.nvim_create_buf(false, false)
	vim.api.nvim_create_autocmd("LspAttach", {
		once = true,
		callback = function(ev)
			if ev.buf ~= buf then
				return
			end
			local client_id = ev.data.client_id
			local client = vim.lsp.get_client_by_id(client_id)
			if client and client.name == "kakehashi" then
				vim.api.nvim_buf_delete(ev.buf, { force = true })
			end

			return true
		end,
	})
	vim.bo[buf].filetype = filetype

	-- extra attach logic
	vim.api.nvim_create_autocmd("FileType", {
		callback = function(ev_ft)
			local client = vim.lsp.get_clients({ name = "kakehashi" })[1]
			if not client then
				return
			end
			local buftype = vim.bo[ev_ft.buf].buftype
			if (buftype == "nofile" or buftype == "help") and vim.api.nvim_buf_get_name(ev_ft.buf) ~= "" then
				vim.lsp.buf_attach_client(ev_ft.buf, client.id)
			end
		end,
	})
end

function M.setup()
	require("atusy.lsp.deno").setup()
	require("atusy.lsp.ddc_completion").setup()

	vim.api.nvim_create_autocmd("FileType", {
		group = M.augroup,
		once = true,
		callback = function()
			pcall(require, "lspconfig")
			vim.lsp.log.set_level(
				vim.env.NVIM_LSP_LOGLEVEL and vim.lsp.log_levels[vim.env.NVIM_LSP_LOGLEVEL] or vim.lsp.log_levels.ERROR
			)
			vim.lsp.linked_editing_range.enable(true)
			vim.lsp.inline_completion.enable(true)
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
					"copilot",
					"kakehashi",
				})
			end)
		end,
	})

	vim.api.nvim_create_autocmd("LspAttach", {
		group = M.augroup,
		once = false, -- because of buffer-local configurations
		callback = function(ctx)
			local client = vim.lsp.get_client_by_id(ctx.data.client_id)
			if client then
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

	vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx)
		local client = vim.lsp.get_client_by_id(ctx.client_id)

		local ignore_pull = { "kakehashi" }
		if client and vim.tbl_contains(ignore_pull, client.name) then
			return
		end

		return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx)
	end

	-- To start kakehashi and underlying tsudoi and optionally fish_lsp
	-- Tsudoi is for common completion, and fish_lsp is for shell command completion on cmdline
	M.start_kakehashi("fish")
end

return M
