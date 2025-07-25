local winid = vim.api.nvim_get_current_win()
local bufnr = vim.api.nvim_get_current_buf()
local bufname = vim.api.nvim_buf_get_name(bufnr)
local bufdir = vim.fs.dirname(bufname)
local is_git_repo = vim.system({ "git", "rev-parse", "--is-inside-work-tree" }, { cwd = bufdir }):wait().code == 0

vim.wo[winid][0].conceallevel = 0

if vim.bo.buftype == "help" then
	vim.cmd("wincmd L | vertical resize 83")
end

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

---@param node TSNode
---@return TSNode | nil
local function find_tag_in_decendant(node)
	for child in node:iter_children() do
		if child:type() == "tag" then
			return child
		end
		local descendant = find_tag_in_decendant(child)
		if descendant then
			return descendant
		end
	end
end

---Find the nearest helptag node in the current block or its previous siblings.
---@param node TSNode
---@return TSNode | nil
local function find_helptag(node)
	local node_ancestor = node ---@type TSNode

	-- Find the nearest ancestor that is a block or tag
	-- if tag, return it
	-- if block, break the loop
	while true do
		if node_ancestor:type() == "tag" then
			return node_ancestor
		end
		if node_ancestor:type() == "block" then
			break
		end
		local node_parent = node_ancestor:parent()
		if not node_parent then
			break
		end
		node_ancestor = node_parent
	end

	-- find tag in the currrent block or the previous siblings of the block
	local node_block = node_ancestor ---@type TSNode | nil
	while true do
		if not node_block then
			break
		end
		local node_tag = find_tag_in_decendant(node_block)
		if node_tag then
			return node_tag
		end
		node_block = node_block:prev_named_sibling()
	end
end

---Get helptag name within *helptag* node.
---@param node TSNode
---@return string
local function get_helptag_name(node)
	local text = node:field("text")
	if text and #text == 1 then
		return vim.treesitter.get_node_text(text[1], 0, {})
	end

	local ret = ""
	for _, child in node:iter_children() do
		ret = ret .. child
	end
	if ret ~= "" then
		return ret
	end

	ret = vim.treesitter.get_node_text(node, 0, {}):gsub("^[*]", ""):gsub("[*]$", "")
	return ret
end

if not is_git_repo then
	-- otherwise, use global mapping defined at ~/.config/nvim/lua/plugins/git/init.lua
	vim.keymap.set("n", "<Plug>(C-G)<C-Y>", function()
		local node_cursor = vim.treesitter.get_node()
		if node_cursor == nil then
			return
		end
		local node_helptag = find_helptag(node_cursor)

		if not node_helptag then
			return
		end

		local node_text = get_helptag_name(node_helptag)
		local file_name = vim.fs.basename(vim.api.nvim_buf_get_name(0)):gsub("[.]txt$", "")
		local url = string.format(
			-- e.g., https://neovim.io/doc/user/editing.html#CTRL-G
			"https://neovim.io/doc/user/%s.html#%s",
			file_name,
			vim.uri_encode(node_text):gsub(":", "%%3A")
		)
		vim.fn.setreg("+", url)
		vim.notify(url)
	end, { buffer = true })
end
