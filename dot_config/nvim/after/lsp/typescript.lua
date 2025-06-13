-- Handle TypeScript/Deno based on project type
local function has_node_modules()
	return vim.fn.isdirectory("node_modules") == 1 or vim.fn.findfile("package.json", ".;") ~= ""
end

if has_node_modules() then
	vim.lsp.config.ts_ls = {}
else
	vim.lsp.config.denols = { single_file_support = true }
end

