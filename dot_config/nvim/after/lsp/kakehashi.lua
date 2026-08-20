local augroup = vim.api.nvim_create_augroup("atusy-lsp-kakehashi", {})

local function gen_cmd()
	local home = vim.uv.os_homedir()
	if not home then
		return { "kakehashi" }
	end

	local KAKEHASHI_BIN = vim.env.KAKEHASHI_BIN or vim.fs.joinpath(home, ".cargo/bin/kakehashi")

	---@type string[]
	local cmd = { vim.uv.fs_stat(KAKEHASHI_BIN) and KAKEHASHI_BIN or "kakehashi" }

	for _, path in ipairs({
		vim.fs.joinpath(home, "ghq/github.com/atusy/kakehashi-lspconfig/lsp.toml"),
		vim.fs.joinpath(home, ".config/kakehashi/kakehashi.toml"),
		"kakehashi.toml",
	}) do
		if vim.uv.fs_stat(path) then
			table.insert(cmd, "--config-file")
			table.insert(cmd, path)
		end
	end

	---@type string[]
	local extra_args = vim.json.decode(vim.env.KAKEHASHI_EXTRA_ARGS or "[]")
	for _, arg in ipairs(extra_args) do
		table.insert(cmd, arg)
	end

	return cmd
end

---@type vim.lsp.Config
return {
	cmd = gen_cmd(),
	cmd_env = {
		KAKEHASHI_EXPERIMENTAL = vim.env.KAKEHASHI_EXPERIMENTAL or "true",
	},
	root_dir = function(bufnr, on_dir)
		-- skip terminal buffers (e.g., toggleterm)
		if vim.bo[bufnr].buftype == "terminal" then
			return
		end
		local ft = vim.bo[bufnr].filetype
		if ft == "toggleterm" then
			return
		end

		local bufname = vim.api.nvim_buf_get_name(bufnr)
		if bufname:find(" ", 1, true) then
			vim.notify("Skip attaching to kakehashi due to spaces in bufname: " .. bufname, vim.log.levels.WARN)
			return
		end

		on_dir()
	end,
	on_init = function(client)
		-- to use semanticTokens/full/delta
		client.server_capabilities.semanticTokensProvider.range = false

		-- attach files skipped by vim.lsp.enable()
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      callback = function(ev_ft)
        local buftype = vim.bo[ev_ft.buf].buftype
        if (buftype == "nofile" or buftype == "help") and vim.api.nvim_buf_get_name(ev_ft.buf) ~= "" then
          vim.lsp.buf_attach_client(ev_ft.buf, client.id)
        end
      end,
    })
	end,
	on_exit = function()
	  vim.api.nvim_clear_autocmds({ group = augroup })
  end,
	on_attach = function(_, bufnr)
		vim.api.nvim_create_autocmd("LspTokenUpdate", {
			buffer = bufnr,
			once = true,
			callback = function()
				-- order matters
				vim.treesitter.stop(bufnr)
				vim.opt_local.syntax = "OFF"
			end,
		})
	end,
	init_options = {
		languageServers = {
			basedpyright = { settings = vim.lsp.config.basedpyright.settings },
			jsonls = { settings = vim.lsp.config.jsonls.settings },
			lua_ls = { settings = vim.lsp.config.lua_ls.settings },
			r_language_server = { settings = vim.lsp.config.r_language_server.settings },
			rust_analyzer = { settings = vim.lsp.config.rust_analyzer.settings },
			yamlls = { settings = vim.lsp.config.yamlls.settings },
		},
	},
}
