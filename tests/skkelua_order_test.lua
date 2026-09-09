vim.opt.rtp:prepend(vim.fn.getcwd() .. "/dot_config/nvim")
local learned
package.loaded.skkelua = {
	is_enabled = function()
		return true
	end,
	phase = function()
		return "input:okurinasi"
	end,
	get_pre_edit = function()
		return "あ"
	end,
	get_prefix = function()
		return "あ"
	end,
	get_ranks = function()
		return { { "甲;one", 5 }, { "丙", 5 } }
	end,
	get_completion_result = function()
		return {
			{ "い", { "同;second", "丙" } },
			{ "あ", { "同;first", "乙;annotation", "甲;one" } },
			{ ">あ", { ">接;prefix" } },
			{ "あ>", { "尾>;suffix" } },
		}
	end,
	complete_callback = function(midasi, word)
		learned = { midasi, word }
	end,
}
local provider = require("atusy.lsp.skkelua")
local result = provider.complete({ position = { line = 0, character = 1 } }, { text = "あ" })
assert(vim.deep_equal(
	vim.tbl_map(function(item)
		return item.label
	end, result.items),
	{ "甲", "丙", "接", "同", "乙", "尾" }
))
assert(result.items[4].data.word == "同;first", "duplicate keeps the first dictionary entry")
assert(result.items[5].detail == "annotation")
for i, item in ipairs(result.items) do
	assert(item.sortText == ("%06d"):format(i))
end
provider.on_complete_done({ __sourceName = "skkelua-cmdline", abbr = "同" })
assert(vim.deep_equal(learned, { "あ", "同;first" }))
print("PASS ranked candidates retain dictionary order, deduplication, affixes and learning")
