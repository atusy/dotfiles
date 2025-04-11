local function list_items()
	local items = {}
	local completion = require("codecompanion.completion")
	for _, func in pairs({ "slash_commands", "tools", "variables" }) do
		for _, v in pairs(completion[func]()) do
			table.insert(items, { word = v.label, info = v.detail, kind = v.type })
		end
	end
	return items
end

local function patch_buffer()
	local sources = vim.fn["ddc#custom#get_global"]()["sources"] or {}
	table.insert(sources, 1, "parametric")
	vim.fn["ddc#custom#patch_buffer"]({
		sources = sources,
		specialBufferCompletion = true,
		sourceOptions = {
			parametric = {
				mark = "",
				minKeywordLength = 1,
				minAutoCompleteLength = 1,
				keywordPattern = "^[/@#][^\\s]*",
				matchers = { "matcher_head_dictionary", "matcher_fuzzy" },
				converters = { "converter_fuzzy" },
				sorters = { "sorter_fuzzy" },
			},
		},
		sourceParams = {
			parametric = { items = list_items() },
		},
	})
end

local function setup()
	local augroup = vim.api.nvim_create_augroup("atusy-ddc-codecompanion", {})
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "codecompanion",
		group = augroup,
		callback = function()
			local ok = pcall(require, "codecompanion")
			if not ok then
				return true -- remove autocmd
			end
			patch_buffer()
		end,
	})
end

return setup
