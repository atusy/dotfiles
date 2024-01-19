local M = {}

function M.create_visual_converter(callback)
	return function()
		local reg_z = vim.fn.getreginfo("z")
		vim.cmd('noautocmd normal! "zygv')
		local vtext = vim.fn.getreg("z")
		vim.fn.setreg("z", reg_z)

		local encoded = callback(vtext)
		vim.cmd("normal! c" .. encoded)
	end
end

M.urlencode = M.create_visual_converter(function(...)
	vim.uri_encode(...)
end)

M.urldecode = M.create_visual_converter(function(...)
	vim.uri_decode(...)
end)

function M.sample(x)
	local _x, y = { unpack(x) }, {}
	for _ = 1, #x do
		table.insert(y, table.remove(_x, math.random(#_x)))
	end
	return y
end

function M.jump_file(forward)
	local buf_cur = vim.api.nvim_get_current_buf()
	local jumplist = vim.fn.getjumplist()
	local jumps = jumplist[1]
	local idx_cur = jumplist[2] + 1
	local function is_target(buf)
		return buf ~= buf_cur and vim.api.nvim_buf_is_loaded(buf)
	end

	if forward then
		for i = 1, #jumps - idx_cur do
			if is_target(jumps[idx_cur + i].bufnr) then
				return i .. "<C-I>"
			end
		end
	else
		for i = 1, idx_cur - 1 do
			if is_target(jumps[idx_cur - i].bufnr) then
				return i .. "<C-O>"
			end
		end
	end
end

function M.move_floatwin(row, col)
	local conf = vim.api.nvim_win_get_config(0)
	if conf.relative == "" then
		return false
	end
	for k, v in pairs({ row = row, col = col }) do
		if type(conf[k]) == "table" then
			conf[k][false] = conf[k][false] + v
		else
			conf[k] = conf[k] + v
		end
	end
	vim.api.nvim_win_set_config(0, conf)
	return true
end

---@param path string
function M.in_cwd(path)
	return vim.startswith(path, vim.uv.cwd() .. "/") ---@diagnostic disable-line: undefined-field
end

function M.get_visualpos()
	local m = vim.api.nvim_get_mode().mode
	if m ~= "v" and m ~= "V" and m ~= "" then
		return
	end
	local w = vim.api.nvim_get_current_win()
	local pos1 = vim.api.nvim_win_get_cursor(w)
	vim.cmd("normal! o")
	local pos2 = vim.api.nvim_win_get_cursor(w)
	vim.cmd("normal! o")

	local row1, col1, row2, col2 = pos1[1], pos1[2], pos2[1], pos2[2]
	if row1 < row2 then
		return { row1, col1, row2, col2 }
	end
	if row2 < row1 then
		return { row2, col2, row1, col1 }
	end
	if col1 < col2 then
		return { row1, col1, row2, col2 }
	end
	return { row2, col2, row1, col1 }
end

function M.get_visualtext()
	local m = vim.api.nvim_get_mode().mode
	local p = M.get_visualpos()
	if not p then
		return
	end
	local lines = vim.api.nvim_buf_get_lines(0, p[1] - 1, p[3], false)
	if m == "V" then
		return lines
	end
	local anychar = vim.regex(".")
	if m == "" then
		for i, line in pairs(lines) do
			local tail = line:sub(p[4] + 1)
			if tail ~= "" then
				local _, n = anychar:match_str(tail)
				line = line:sub(1, p[4] + n)
			end
			lines[i] = line:sub(p[2] + 1)
		end
		return lines
	end
	if m == "v" then
		local lastline = lines[#lines]
		local _, n = anychar:match_str(lastline:sub(p[4] + 1))
		if n then
			lines[#lines] = lines[#lines]:sub(1, p[4] + n)
		end
		lines[1] = lines[1]:sub(p[2] + 1)
		return lines
	end
end

---@param opts? { cfile: string?, on_none: fun(str): nil }
function M.open_cfile(opts)
	opts = opts or {}
	if not opts.cfile then
		local visual = M.get_visualtext()
		if visual then
			for _, v in pairs(visual) do
				vim.print(v)
				M.open_cfile(vim.tbl_extend("force", opts, { cfile = v }))
			end
			return
		end
	end
	local cfile = opts.cfile or vim.fn.expand("<cfile>") --[[@as string]]

	-- Open URLs in browser
	if cfile:match("^https?://") then
		vim.ui.open(cfile)
		return
	end

	if not vim.uv.fs_stat(cfile) then ---@diagnostic disable-line: undefined-field
		if type(opts.on_none) == "function" then
			opts.on_none(cfile)
		end
		return
	end

	-- Open non-text in browser
	local needs_ui_open = {
		png = true,
		jpg = true,
	}
	local suffix, cnt = cfile:gsub(".*%.", "")
	if cnt == 1 and needs_ui_open[suffix:lower()] then
		vim.ui.open(cfile)
		return
	end

	-- Fallback to gF
	vim.cmd([[normal! gF]])
end

function M.require(name)
	pcall(function()
		require("plenary.reload").reload_module(name)
	end)
	return require(name)
end

local function notify_error(err)
	vim.notify(err, vim.log.levels.ERROR)
end

function M.safely(f, default, handler)
	return function(...)
		local ok, res = pcall(f, ...)
		if not ok then
			return default, (handler or notify_error)(res)
		end
		return res
	end
end

return M
