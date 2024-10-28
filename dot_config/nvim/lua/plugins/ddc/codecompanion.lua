local items = {
	{
		word = "#buffer",
		info = "Share current buffer or its specific lines with `#buffer:8-20`",
	},
	{ word = "#lsp", info = "Share LSP info and code for the current buffer" },
	{ word = "#viewport", info = "Share the buffers and lines in the viewport" },
	{ word = "/buffer" },
	{ word = "/fetch" },
	{ word = "/file" },
	{ word = "/help" },
	{ word = "/now" },
	{ word = "/terminal" },
	{ word = "@code_runner" },
	{ word = "@editor" },
	{ word = "@rag" },
}

local function setup()
	local augroup = vim.api.nvim_create_augroup("atusy-ddc-codecompanion", {})
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "codecompanion",
		group = augroup,
		callback = function()
			vim.fn["ddc#custom#patch_buffer"]("specialBufferCompletion", true)
			vim.fn["ddc#custom#patch_buffer"]({
				sources = { "parametric" },
				backspaceCompletion = true,
				sourceOptions = {
					around = { mark = "", isVolatile = true, maxItems = 1 },
					parametric = {
						mark = "",
						minKeywordLength = 1,
						minAutoCompleteLength = 1,
						keywordPattern = "^[#;]*[a-zA-Z0-9]*",
						matchers = { "matcher_head_dictionary", "matcher_fuzzy" },
						converters = { "converter_fuzzy" },
						sorters = { "sorter_fuzzy" },
					},
				},
				sourceParams = {
					parametric = { items = items },
				},
			})
		end,
	})
end

return setup
