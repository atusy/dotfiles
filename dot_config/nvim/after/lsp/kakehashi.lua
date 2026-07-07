local home = vim.uv.os_homedir()
if not home then
	return
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

---@type vim.lsp.Config
return {
	cmd = cmd,
	cmd_env = {
		KAKEHASHI_EXPERIMENTAL = vim.env.KAKEHASHI_EXPERIMENTAL or "true",
	},
	root_dir = function(bufnr, on_dir)
		-- skip terminal buffers (e.g., toggleterm)
		if vim.bo[bufnr].buftype == "terminal" then
			return
		end
		local ft = vim.bo[bufnr].filetype
		if ft == "gin-buffer" or ft == "toggleterm" then
			return
		end
		on_dir()
	end,
	on_init = function(client)
		-- to use semanticTokens/full/delta
		client.server_capabilities.semanticTokensProvider.range = false
	end,
	on_attach = function(_, bufnr)
		vim.api.nvim_create_autocmd("LspTokenUpdate", {
			buffer = bufnr,
			once = true,
			callback = function()
				vim.opt_local.syntax = "OFF"
				vim.treesitter.stop(bufnr)
			end,
		})
	end,
}
