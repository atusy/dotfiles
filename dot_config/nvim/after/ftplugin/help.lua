pcall(vim.treesitter.start)
vim.wo[0].conceallevel = 0

local function wincmd_L()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	local wins_help = vim.tbl_filter(function(w)
		return "help" == vim.bo[vim.api.nvim_win_get_buf(w)].filetype
	end, wins)
	if #wins_help == 1 then
		local nm = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(wins_help[1]))
		if not vim.startswith(nm, vim.fn.getcwd()) then
			vim.api.nvim_win_call(wins_help[1], function()
				vim.cmd("wincmd L")
			end)
		end
	end
end

-- Run on FileType event
wincmd_L()

-- Run on BufWinEnter
vim.api.nvim_create_autocmd("BufWinEnter", {
	buffer = vim.api.nvim_get_current_buf(),
	callback = wincmd_L,
})

-- Enhanced K
vim.keymap.set("n", "K", function()
	local node = vim.treesitter.get_node()
	while node do
		local t = node:type()
		if t == "tag" or t:match("link$") then
			return "K"
		end
		if t == "url" then
			return string.format([[<Cmd>lua vim.ui.open("%s")<CR>]], vim.treesitter.get_node_text(node, 0, {}))
		end
		node = node:parent()
	end
	return "gF"
end, { expr = true, buffer = true, desc = "Go to definition, open url, or open file" })
