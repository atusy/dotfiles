-- Treesitter-driven endwise recipe for nvim-insx, with a regex fallback.
--
-- Approach B (primary): replicate nvim-treesitter-endwise's detection by reusing
-- its bundled `endwise` tree-sitter queries (queries/<lang>/endwise.scm, kept on
-- runtimepath) so that insx owns the <CR> key instead of a separate on_key hook.
-- Approach A (fallback): insx's built-in regex endwise recipe handles filetypes
-- without a tree-sitter query (e.g. html).
--
-- The detection helpers below are ported from
-- nvim-treesitter-endwise/lua/nvim-treesitter/endwise.lua. Only the *detection*
-- half is kept; insertion is delegated to insx's <CR> mechanics, so the upstream
-- buffer-mutation code (add_end_node, shiftcount, trailing-text splitting) is not
-- reproduced.

local insx = require("insx")

local M = {}

local indent_regex = vim.regex([[\v^\s*\zs\S]])

-- compatibility shim for the breaking change to add_directive on 0.10+
local directive_opts = vim.fn.has("nvim-0.10") == 1 and { force = true, all = false } or true

local function strip_leading_whitespace(line)
	local indent_end = indent_regex:match_str(line)
	if indent_end then
		return string.sub(line, 0, indent_end), string.sub(line, indent_end + 1)
	end
	return line, ""
end

local function text_for_range(range)
	local srow, scol, erow, ecol = unpack(range)
	if srow == erow then
		return string.sub(vim.fn.getline(srow + 1), scol + 1, ecol)
	end
	return string.sub(vim.fn.getline(srow + 1), scol + 1, -1) .. string.sub(vim.fn.getline(erow + 1), 1, ecol)
end

local function point_in_range(row, col, range)
	return not (
		row < range[1]
		or row == range[1] and col < range[2]
		or row > range[3]
		or row == range[3] and col >= range[4]
	)
end

---Whether `node` still needs its closing keyword (mirrors upstream lacks_end).
local function lacks_end(node, end_text)
	local end_node = node:child(node:child_count() - 1)
	if end_node == nil then
		return true
	end
	if end_node:type() ~= end_text then
		return false
	end
	if end_node:missing() then
		return true
	end

	local node_range = { node:range() }
	local indentation = strip_leading_whitespace(vim.fn.getline(node_range[1] + 1))
	local end_node_range = { end_node:range() }
	local end_node_indentation = strip_leading_whitespace(vim.fn.getline(end_node_range[1] + 1))
	local crow = unpack(vim.api.nvim_win_get_cursor(0))
	if indentation == end_node_indentation or end_node_range[3] == crow - 1 then
		return false
	end

	local parent = node:parent()
	while parent ~= nil do
		if parent:has_error() then
			return true
		end
		parent = parent:parent()
	end
	return false
end

-- #endwise! tree-sitter directive (ported verbatim so the bundled queries parse
-- even though the upstream runtime module is never required).
vim.treesitter.query.add_directive("endwise!", function(match, _, _, predicate, metadata)
	metadata.endwise_end_text = predicate[2]
	metadata.endwise_end_suffix = match[predicate[3]]
	metadata.endwise_end_node_type = predicate[4]
	metadata.endwise_shiftcount = predicate[5] or 1
	metadata.endwise_end_suffix_pattern = predicate[6] or "^.*$"
end, directive_opts)

---Resolve the closing keyword to insert at the cursor, or nil if none applies.
---@param bufnr integer
---@return string?
local function detect_end_text(bufnr)
	local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype or "")
	if not lang then
		return nil
	end

	local parser = vim.treesitter.get_parser(bufnr, lang, { error = false })
	if not parser then
		return nil
	end

	-- closest non-whitespace at/before the cursor (mirrors upstream behaviour)
	local row, col = unpack(vim.fn.searchpos([[\S]], "nbcW"))
	if row == 0 then
		return nil
	end
	row, col = row - 1, col - 1

	parser:parse({ row, row + 1 })

	local lang_tree = parser:language_for_range({ row, col, row, col })
	lang = lang_tree:lang()
	if not lang then
		return nil
	end

	local node = vim.treesitter.get_node({
		bufnr = bufnr,
		lang = lang,
		pos = { row, col },
		ignore_injections = true,
	})
	if not node then
		return nil
	end

	local root = node:tree():root()
	if not root then
		return nil
	end

	local query = vim.treesitter.query.get(lang, "endwise")
	if not query then
		return nil
	end

	local srow, _, erow = root:range()
	for _, match, metadata in query:iter_matches(root, bufnr, srow, erow + 1, { all = true }) do
		local cursor_node, endable_node
		for id, n in pairs(match) do
			if type(n) == "table" then
				n = n[#n]
			end
			local capture = query.captures[id]
			if capture == "cursor" then
				cursor_node = n
			elseif capture == "endable" then
				endable_node = n
			end
		end

		if cursor_node and point_in_range(row, col, { cursor_node:range() }) then
			local end_node_type = metadata.endwise_end_node_type or metadata.endwise_end_text
			if not endable_node or lacks_end(endable_node, end_node_type) then
				local end_text = metadata.endwise_end_text
				local suffix_node = metadata.endwise_end_suffix
				if suffix_node then
					if type(suffix_node) == "table" then
						suffix_node = suffix_node[#suffix_node]
					end
					local suffix = text_for_range({ suffix_node:range() })
					local s, e = vim.regex(metadata.endwise_end_suffix_pattern):match_str(suffix)
					if s then
						suffix = string.sub(suffix, s + 1, e)
					end
					end_text = end_text .. suffix
				end
				return end_text
			end
		end
	end
	return nil
end

M.detect_end_text = detect_end_text

---@return insx.RecipeSource
local function recipe()
	return {
		priority = 100, -- take precedence over the regex fallback and pair recipes
		enabled = function()
			return detect_end_text(0) ~= nil
		end,
		action = function(ctx)
			local end_text = detect_end_text(0)
			if not end_text then
				-- buffer changed since `enabled`; defer to the next recipe instead
				-- of swallowing the <CR>.
				return ctx.next()
			end
			local row, col = ctx.row(), ctx.col()
			ctx.send("<CR>" .. end_text)
			ctx.move(row, col)
			ctx.send("<CR>")
		end,
	}
end

function M.setup()
	-- approach B (primary): tree-sitter driven detection across every language
	-- that ships an endwise query.
	insx.add("<CR>", recipe())

	-- approach A (fallback): insx's built-in regex endwise for filetypes without
	-- a tree-sitter query. Lower priority, so it only fires when detection misses.
	local endwise = require("insx.recipe.endwise")
	insx.add(
		"<CR>",
		endwise({
			lua = endwise.builtin.lua,
			html = endwise.builtin.html,
		})
	)
end

return M
