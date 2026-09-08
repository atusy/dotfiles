local function get_libraries()
	local ok, libraries = pcall(function()
		return vim.tbl_map(function(plugin)
			return plugin.dir
		end, vim.tbl_values(require("lazy.core.config").plugins))
	end)
	if not ok then
		return { vim.env.VIMRUNTIME }
	end
	table.insert(libraries, vim.env.VIMRUNTIME)
	return libraries
end

---@type vim.lsp.Config
return {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim", "pandoc" } },
			workspace = {
				library = get_libraries(),
				checkThirdParty = false,
			},
			format = { enable = false },
			semantic = { enable = false },
		},
	},
}
