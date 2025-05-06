---@param node? TSNode
---@param _type string
---@return TSNode?
local function find_child(node, _type)
	if node then
		for n in node:iter_children() do
			if n:type() == _type then
				return n
			end
		end
	end
end

---@param patch TSNode
---@param line TSNode
---@return string?
local function unifieddiff_filename(patch, line)
	local line_deleted = line:type() == "line_deleted"
	local filename_node = find_child(
		find_child(find_child(patch, "header"), line_deleted and "from_file_line" or "to_file_line"),
		"filename"
	)
	if not filename_node then
		return
	end
	local filename = vim.treesitter.get_node_text(filename_node, 0):gsub("^[ab]/", "")
	return filename
end

---@param hunk TSNode
---@param line TSNode
---@return integer?
local function unifieddiff_row(hunk, line)
	local row = 0
	local line_type = line:type() == "line_deleted" and "line_deleted" or "line_added"
	local line_id = line:id()
	for n in hunk:iter_children() do
		local t = n:type()
		if t == "hunk_info" then
			local hunk_location = find_child(find_child(n, "hunk_range_new"), "hunk_location")
			if not hunk_location then
				return
			end
			local num = tonumber(vim.treesitter.get_node_text(hunk_location, 0))
			if not num then
				return
			end
			row = num
		end
		if n:id() == line_id then
			return row
		end
		if t == "line_nochange" or t == line_type then
			row = row + 1
		end
	end
end

---@return { filename: string?, pos: {[1]: integer, [2]: integer}, type: string }?
local function unifieddiff_location()
	-- body
	local body = vim.treesitter.get_node()
	if not body or body:type() ~= "body" then
		return
	end

	-- line
	local line = body:parent()
	local line_type = line and line:type()
	if not line or not ({ line_added = true, line_deleted = true, line_nochange = true })[line_type] then
		return
	end

	-- hunk
	local hunk = line:parent()
	if not hunk or hunk:type() ~= "hunk" then
		return
	end

	-- patch
	local patch = hunk:parent()
	if not patch or patch:type() ~= "patch" then
		return
	end

	return {
		filename = unifieddiff_filename(patch, line),
		pos = { unifieddiff_row(hunk, line), vim.api.nvim_win_get_cursor(0)[2] - 1 },
		type = line_type,
	}
end

---@param filename string
---@return number
local function get_buf(filename)
	local buf = vim.fn.bufadd(filename)
	if vim.fn.bufloaded(buf) ~= 1 then
		vim.fn.bufload(buf)
	end
	return buf
end

--- open or focus the hover
---@param opts? { bufnr?: integer, pos?: {[1]: integer, [2]: integer}, relative?: string, providers?: string[] }
local function hover(opts)
	if vim.b.hover_preview and vim.api.nvim_win_is_valid(vim.b.hover_preview) then
		vim.api.nvim_set_current_win(vim.b.hover_preview)
	else
		require("hover").hover(vim.tbl_extend("keep", opts or {}, { providers = { "LSP" } }))
	end
end

--- hover for diff
local function hover_diff()
	local loc = unifieddiff_location()
	if loc and loc.type ~= "line_deleted" and loc.filename and vim.uv.fs_stat(loc.filename) then ---@diagnostic disable-line: undefined-field
		hover({ bufnr = get_buf(loc.filename), pos = loc.pos })
	end
end

return {
	{
		"https://github.com/lewis6991/hover.nvim/",
		lazy = true,
		init = function()
			-- LSP with fallbacks...
			local lhs = "K"
			vim.keymap.set("n", lhs, hover)
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ctx)
					local rhs
					if vim.tbl_contains({ "diff", "gin-diff" }, ctx.match) then
						rhs = hover_diff
					elseif ctx.match == "gitrebase" then
						rhs = function()
							hover({ providers = { "gitshow" } })
						end
					elseif vim.tbl_contains({ "sh", "bash", "fish", "xonsh", "zsh" }, ctx.match) then
						rhs = function()
							hover({ providers = { "LSP", "Man", "cmdhelp" } })
						end
					elseif ctx.match == "man" then
						rhs = "K"
					end
					if rhs then
						vim.keymap.set("n", lhs, rhs, { buffer = ctx.buf })
					end
				end,
			})

			-- gm for get meaning
			vim.keymap.set("n", "gm", function()
				hover({ providers = { "Dictionary" } })
			end)

			-- gh for github
			vim.keymap.set("n", "gh", function()
				hover({ providers = { "GitHub" } })
			end)
		end,
		config = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
					require("hover.providers.gh")
					require("hover.providers.man")
					require("hover.providers.dictionary")
					require("plugins.hover.providers.cmdhelp")
					require("plugins.hover.providers.gitshow")
				end,
				preview_opts = {
					border = "single",
				},
				preview_window = false,
				title = false,
				mouse_providers = {},
			})
		end,
	},
}
