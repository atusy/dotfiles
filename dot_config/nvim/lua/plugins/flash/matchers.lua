local M = {}

---@param lines string[] lines to be searched
---@param pat string | fun(s: string): number?, number? regex or a function that receives a string to be searched and returns the location of the match
---@param col1 number? ignore the number of characters in the head of lines[1]
---@param col2 number? ignore the number of characters in the tail of lines[#lines]
---@param row number? the line number of the first line
local function search_lines(lines, pat, col1, col2, row)
	row = row or 0
	col1 = col1 or 0
	col2 = col2 or 0
	local match_str = pat
	if type(pat) == "string" then
		local re = vim.regex(pat)
		match_str = function(...)
			return re:match_str(...)
		end
	end

	local n = #lines
	local matches = {}
	for i, line in pairs(lines) do
		local s = line -- string to be searched
		local col = 0 -- search from the first character by default

		-- if the last line, ignore tail by co2
		if i == n and col2 > 0 then
			s = s:sub(0, col2 - 1) -- do not search beyond col2
		end

		-- if the first line, ignore head by col1
		if i == 1 then
			col = col1
			s = s:sub(col1 + 1)
		end

		-- each iteration trims head of s so to find next match
		while s ~= "" do
			local first, last = match_str(s)
			if not first then
				break
			end
			table.insert(matches, {
				pos = { row + i, first + col },
				end_pos = { row + i, last + col - 1 },
			})
			s = s:sub(first + 1)
			local idx = vim.fn.byteidx(s, 1)
			s = s:sub(idx + 1)
			col = col + first + idx
		end
	end
	return matches
end

local function search(buf, pat, start, _end, strict_indexing)
	start = start or { 0, 0 }
	_end = _end or { start[1] + 1, 0 }
	local lines = vim.api.nvim_buf_get_lines(buf, start[1], _end[1], strict_indexing or true)
	return search_lines(lines, pat, start[2], _end[2], start[1]), table.concat(lines, "\n")
end

function M.char_matcher(conv, forward)
	local f = function(win, state)
		local curwin = vim.api.nvim_get_current_win()
		if win ~= curwin or state.pattern.pattern == "" then
			return {}
		end
		local buf = vim.api.nvim_win_get_buf(win)
		local cursor = vim.api.nvim_win_get_cursor(win)
		local bot = cursor[1]
		local top = bot - 1
		local left = forward and cursor[2] or 0
		local right = forward and 0 or cursor[2]
		local matches = search(buf, conv(state.pattern.pattern), { top, left }, { bot, right })
		local labels = string.sub(state.opts.labels, 0, #matches)
		local delta = forward and 1 or -1
		local i = forward and 1 or #matches
		for lab in labels:gmatch(".") do
			matches[i].label = lab
			i = i + delta
		end
		return matches
	end
	return require("atusy.utils").safely(f, {})
end

local function sort(tbl, win)
	local cursor = vim.api.nvim_win_get_cursor(win)
	table.sort(tbl, function(a, b)
		if a.label and not b.label then
			return false
		end
		if b.label and not a.label then
			return true
		end
		local ap, bp = a.pos, b.pos
		if ap[1] == bp[1] then
			return ap[2] < bp[2]
		end
		local dya = cursor[1] - ap[1]
		local dyb = cursor[1] - bp[1]
		return dya * dya < dyb * dyb
	end)
	return tbl
end

local function conv_default(str)
	return [[\c]] .. require("plugins.flash.query").kensaku(str)
end

local function key(m)
	return "w" .. m.win .. "r" .. m.pos[1] .. "c" .. m.pos[2]
end

function M.incremental_matcher(conv, cache)
	local curwin = vim.api.nvim_get_current_win()
	conv = conv or conv_default
	if cache then
		cache.labels = {}
	end
	return require("atusy.utils").safely(function(win, state)
		local wininfo = vim.fn.getwininfo(win)
		if win ~= curwin or state.pattern.pattern == "" or not wininfo or #wininfo == 0 then
			return {}
		end
		local buf, top, bot = wininfo[1].bufnr, wininfo[1].topline - 1, wininfo[1].botline
		local matches, lines = search(buf, conv(state.pattern.pattern), { top, 0 }, { bot, 0 })
		local test = setmetatable({}, {
			__index = function(self, k)
				if string.match(k, "[ABCDEFGHIJKLMNOPQRSTUVWXYZ]") then
					self[k] = true
				else
					local ok, re = pcall(vim.regex, conv(state.pattern.pattern .. k))
					self[k] = not ok or (re and not re:match_str(lines))
				end
				return self[k]
			end,
		})
		local used = {}

		-- 候補にwinidの付与し、可能ならキャッシュから前回からラベルを継承する
		for _, m in pairs(matches) do
			m.win = win
			local k = key(m)
			local lab = cache and cache.labels[k]
			if lab then
				if test[lab] then
					m.label = lab
					used[lab] = true
				else
					cache.labels[k] = nil
				end
			end
		end

		-- multi_window対応時への備え
		if win == curwin then
			matches = sort(matches, win)
		end

		-- ラベルを持たない候補に可能な限りラベルをあたえる
		for _, m in pairs(matches) do
			if m.label then
				-- sortでlabel付きを後ろにしてある
				return matches
			end
			local it = string.gmatch(state.opts.labels, ".")
			for lab in it do
				if not used[lab] and test[lab] then
					used[lab] = true
					m.label = lab
					break
				end
			end
			if not it() then
				return matches
			end
		end
		return matches
	end, {})
end

return M
