local M = {}

---@param node TSNode?
---@return TSNode[]
function M.list_ancestor_nodes(node)
	local ancestors = {} ---@type TSNode[]
	while node do
		table.insert(ancestors, node)
		node = node:parent()
	end
	return ancestors
end

---Treesitter-based foldtext
---
---Modified after https://github.com/neovim/neovim/blob/7f9fc2fbf03e18c1e4033763be4905707d7a84e7/runtime/lua/vim/treesitter/_fold.lua?plain=1#L402-L491
---under Apache License Version 2.0, January 2004 https://www.apache.org/licenses/
---
---With this change, foldtext may include lines after foldstart.
---For example, foldtext from the following situation is `function f( a, b, c )`.
---
---function f( -- foldstart
---  a,
---  b,
---  c
--- ) -- foldend
---  return a, b, c
---end
---
---@return { [1]: string, [2]: string[] }[]|string
function M.foldtext()
	local foldstart = vim.v.foldstart
	local bufnr = vim.api.nvim_get_current_buf()

	local line = vim.api.nvim_buf_get_lines(bufnr, foldstart - 1, foldstart, false)[1]
	if not line then
		return vim.fn.foldtext()
	end

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, nil, { ignore_injections = false })
	if not ok or not parser then
		return vim.fn.foldtext()
	end

	-- Parse only the required range for better performance
	local trees = parser:parse({ foldstart - 1, foldstart })
	if not trees then
		return vim.fn.foldtext()
	end

	---@type { [1]: string, [2]: string[], range: { [1]: integer, [2]: integer } }[] | { [1]: string, [2]: string[] }[]
	local result = {}

	-- iterate captures up to the end row of the node at the last character of the startline
	-- sometimes, the value is too large because the character might be ignored by treesitter
	-- (e.g., trailing space)
	local row = vim.treesitter
		.get_node({ bufnr = bufnr, pos = { foldstart - 1, line:len() }, ignore_injections = false })
		:end_()
	local line_positions = {}
	local lines = {}
	for i, v in ipairs(vim.api.nvim_buf_get_lines(bufnr, foldstart - 1, row + 1, false)) do
		line_positions[foldstart - 2 + i] = 0
		lines[foldstart - 2 + i] = v
	end

	local text_concatenated = ""
	local text_maxwidth = vim.api.nvim_win_get_width(0) * 2

	-- Collect and sort captures from all trees (including injections) in one pass
	---@type {id: integer, node: TSNode, metadata: table, query: vim.treesitter.Query, start_row: integer, start_col: integer}[]
	local all_captures = {}

	-- Use for_each_tree to iterate through all trees including injections
	parser:for_each_tree(function(tree, ltree)
		local lang = ltree:lang()
		local query = vim.treesitter.query.get(lang, "highlights")
		if query then
			for id, node, metadata in query:iter_captures(tree:root(), bufnr, foldstart - 1, row + 1) do
				-- Cache node range to avoid duplicate calls
				local start_row, start_col, end_row, end_col = node:range()
				-- Pre-filter: only collect captures within the fold range
				if start_row >= foldstart - 1 and end_row <= row then
					table.insert(all_captures, {
						id = id,
						node = node,
						metadata = metadata,
						query = query,
						start_row = start_row,
						start_col = start_col,
					})
				end
			end
		end
	end)

	-- Sort by cached position values
	table.sort(all_captures, function(a, b)
		if a.start_row ~= b.start_row then
			return a.start_row < b.start_row
		end
		return a.start_col < b.start_col
	end)

	for _, capture in ipairs(all_captures) do
		-- Early exit if we've exceeded max width
		if vim.fn.strdisplaywidth(text_concatenated) > text_maxwidth then
			break
		end

		local id, node, metadata, query = capture.id, capture.node, capture.metadata, capture.query
		local start_row, start_col = capture.start_row, capture.start_col
		local name = query.captures[id]
		local priority = tonumber(metadata.priority or vim.highlight.priorities.treesitter)

		-- Get end position only when needed (already filtered by range)
		local _, _, _, end_col = node:range()

		-- check for characters ignored by treesitter
		if start_col > line_positions[start_row] or start_col == 0 then
			local text = lines[start_row]:sub(line_positions[start_row] + 1, start_col)
			if line_positions[start_row] == 0 and start_row > foldstart - 1 then
				text = " "
			end
			table.insert(result, { text, {}, range = { line_positions[start_row], start_col } })
			text_concatenated = text_concatenated .. text
		end
		line_positions[start_row] = end_col

		local text = lines[start_row]:sub(start_col + 1, end_col)
		table.insert(result, { text, { { "@" .. name, priority } }, range = { start_col, end_col } })
		text_concatenated = text_concatenated .. text
	end

	local i = 1
	while i <= #result do
		-- find first capture that is not in current range and apply highlights on the way
		local j = i + 1
		while j <= #result and result[j].range[1] >= result[i].range[1] and result[j].range[2] <= result[i].range[2] do
			for k, v in ipairs(result[i][2]) do
				if not vim.tbl_contains(result[j][2], v) then
					table.insert(result[j][2], k, v)
				end
			end
			j = j + 1
		end

		-- remove the parent capture if it is split into children
		if j > i + 1 then
			table.remove(result, i)
		else
			-- highlights need to be sorted by priority, on equal prio, the deeper nested capture (earlier
			-- in list) should be considered higher prio
			if #result[i][2] > 1 then
				table.sort(result[i][2], function(a, b)
					return a[2] < b[2]
				end)
			end

			result[i][2] = vim.tbl_map(function(tbl)
				return tbl[1]
			end, result[i][2])
			result[i] = { result[i][1], result[i][2] }

			i = i + 1
		end
	end

	return result
end

local is_open_neovim_32660 ---@type boolean | nil

--- An autocmd callback to workaround flickering of async highlight
function M.workaround_flickering(ctx)
	-- remove autocmd if the issue is closed
	local issue = "https://github.com/neovim/neovim/issues/32660"
	if is_open_neovim_32660 == nil then
		pcall(vim.system, {
			"gh",
			"issue",
			"view",
			issue,
			"--json",
			"state",
			"--jq",
			".state",
		}, { text = true }, function(obj)
			if obj.code ~= 0 then
				-- e.g., when command is not available or network is disconnected
				return
			end
			is_open_neovim_32660 = obj.stdout:gsub("\n", ""):match("^OPEN$") ~= nil
			if not is_open_neovim_32660 then
				vim.schedule(function()
					vim.notify("Update neovim to experience TS async highlight without flickering: " .. issue)
				end)
			end
		end)
	end

	local function is_parsing(buf)
		-- try undocumented `vim.treesitter.highlighter`
		local ok, active = pcall(function()
			return vim.treesitter.highlighter.active[buf] ~= nil
		end)
		if ok then
			return active
		end

		-- otherwise, assume that the parser is active if the buffer is parsable
		local parsable = pcall(vim.treesitter.get_parser, buf)
		return parsable
	end

	local function exec()
		local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
		local bufs = {}
		for _, win in ipairs(wins) do
			local buf = vim.api.nvim_win_get_buf(win)
			if bufs[buf] == nil then
				bufs[buf] = true
			elseif bufs[buf] == true then
				if is_parsing(buf) then
					vim.g._ts_force_sync_parsing = true
					return
				end
				-- set to false to avoid multiple tests on the availability of parser
				bufs[buf] = false
			end
		end
		vim.g._ts_force_sync_parsing = false
	end

	if ctx.event == "WinClosed" then
		return vim.schedule(exec)
	end
	return exec()
end

return M
