local M = {}

---@param nodes TSNode[]
---@return string?
local function expand_captured_url(nodes)
	local url ---@type TSNode?
	for _, node in pairs(nodes) do
		local row, col = node:range()
		local captures = vim.treesitter.get_captures_at_pos(0, row, col)
		for _, capture in pairs(captures) do
			if capture == "markup.link.url" or capture == "string.special.url" then
				url = node
				break
			end
		end
		if not url then
			return url
		end
	end
	return url and vim.treesitter.get_node_text(url, 0, {}) or nil
end

---@param nodes TSNode[]
---@return string?
local function expand_markdown_link(nodes)
	local link_types = { inline_link = true, image = true, link_reference_definition = true }
	for _, node in pairs(nodes) do
		local node_type = node:type()
		if node_type == "uri_autolink" then
			return (vim.treesitter.get_node_text(node, 0, {}):gsub("^<(.*)>$", "%1"))
		end

		if link_types[node_type] then
			for child in node:iter_children() do
				if child:type() == "link_destination" then
					return vim.treesitter.get_node_text(child, 0, {})
				end
			end
		end
	end
end

---@return string, integer?, integer?
function M.expand(opts)
	if opts.cfile then
		return opts.cfile
	end

	local ok, cur_node = pcall(vim.treesitter.get_node, { ignore_injections = false })
	local nodes = require("atusy.treesitter").list_ancestor_nodes(ok and cur_node or nil)

	-- based on node capture
	local captured_url = expand_captured_url(nodes)
	if captured_url then
		return captured_url
	end

	-- based on node type
	local ft = vim.bo.filetype
	if ft == "markdown" then
		local url = expand_markdown_link(nodes)
		if url then
			return url
		end
	end

	-- based on native expand()
	local cWORD = vim.fn.expand("<cWORD>")
	if cWORD:match("^https?://") then
		return cWORD
	end

	local isfname = vim.o.isfname
	vim.opt.isfname:remove(":")
	local cfile1 = vim.fn.expand("<cfile>")
	vim.opt.isfname:append(":")
	local cfile2 = vim.fn.expand("<cfile>")
	vim.o.isfname = isfname

	if cfile1:match("^[0-9]+$") then
		local pos1, cnt1 = cfile2:gsub(".*[^:]:", "")
		if cnt1 == 0 then
			return cfile1
		end

		local pos2, cnt2 = cfile2:gsub(".*[^:]:([0-9]+):" .. pos1, "%1")
		if pos1 ~= cfile1 and pos2 ~= cfile1 then
			return cfile1
		end
		local row, col
		local n = #pos1 + 1
		if cnt2 == 0 then
			row = tonumber(pos1)
		else
			row = tonumber(pos2)
			col = tonumber(pos1)
			n = n + #pos2 + 1
		end

		return cfile2:sub(1, #cfile2 - n), row, col
	end

	if cfile2:sub(1, #cfile1) ~= cfile1 then
		return cfile1
	end

	local suffix = cfile2:sub(#cfile1 + 1)
	local row, col
	if suffix:match("^:[0-9]+$") then
		row = tonumber(suffix:sub(2))
	elseif suffix:match("^:[0-9]+:[0-9]+$") then
		row = tonumber(suffix:match("^:[0-9]+"):sub(2))
		col = tonumber(suffix:match(":[0-9]+$"):sub(2))
	end
	return cfile1, row, col
end

local function fs_stat(x)
	return vim.uv.fs_stat(x) ---@diagnostic disable-line: undefined-field
end

---@param path string
local function find_file(path)
	local fullpath = vim.fn.fnamemodify(path, ":p")
	if path == fullpath then
		return true, path
	end

	local candidates = {}

	-- find file relative to the current buffer like |gf|
	if vim.bo.buftype == "" then
		local bufname = vim.api.nvim_buf_get_name(0)
		if bufname ~= "" then
			table.insert(candidates, vim.fs.dirname(bufname))
			local candidate = vim.fn.fnamemodify(vim.fs.joinpath(vim.fs.dirname(bufname), path), ":p")
			if fs_stat(candidate) then
				return true, candidate
			end
		end
	end

	if fs_stat(path) then
		return true, path
	end

	return false, path
end

---Open <cfile> if it is an existing file or an URL (enhanced |gF|)
---@param opts? { cmd: string?, cfile: string?, on_none: fun(str): nil  }
function M.open(opts)
	opts = opts or {}
	if not opts.cfile then
		local visual = require("atusy.misc").get_visualtext()
		if visual then
			for _, v in pairs(visual) do
				vim.print(v)
				M.open(vim.tbl_extend("force", opts, { cfile = v }))
			end
			return
		end
	end

	local cfile, row, col = M.expand(opts)

	-- Open URL in browser
	if cfile:match("^https?://") then
		cfile = cfile .. (row and (":" .. row) or "") .. (col and (":" .. col) or "")
		vim.notify(cfile)
		vim.ui.open(cfile)
		return
	end

	local ok, target = find_file(cfile)

	if not ok then
		if type(opts.on_none) == "function" then
			opts.on_none(cfile)
		else
			vim.notify("FileNotFound: " .. cfile, vim.log.levels.ERROR)
		end
		return
	end

	-- Open non-text in browser
	local needs_ui_open = {
		png = true,
		jpg = true,
	}
	local suffix, cnt = target:gsub(".*%.", "")
	if cnt == 1 and needs_ui_open[suffix:lower()] then
		vim.ui.open(target)
		return
	end

	for _, buf in pairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf) == target then
			if opts.cmd then
				vim.cmd(opts.cmd)
			end
			vim.api.nvim_win_set_buf(0, buf)
			if row then
				vim.api.nvim_win_set_cursor(0, { row, col and (col - 1) or 0 })
			end
			return
		end
	end

	local cmd = (opts.cmd or "e") .. " " .. target
	if row then
		cmd = string.format("%s | lua vim.api.nvim_win_set_cursor(0, {%d, %d})", cmd, row, col and (col - 1) or 0)
	end
	vim.cmd(cmd)
end

return M
