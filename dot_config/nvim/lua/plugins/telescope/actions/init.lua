local M = require("telescope.actions.mt").transform_mod({
	search_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("telescope.builtin").quickfix({
			sorter = require("plugins.telescope.sorter").filname_sorter(),
		})
	end,
	--- grep on entry line
	grep_line_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("telescope.builtin").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter({ target = "line" }),
		})
	end,
	--- grep on entry filename
	grep_filename_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("telescope.builtin").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter({ target = "filename" }),
		})
	end,
	--- grep on entry text
	grep_text_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("telescope.builtin").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter({ target = "text" }),
		})
	end,
})

local meta = getmetatable(M)
local index = meta.__index

function meta.__index(self, key)
	if index then
		local res = index(self, key)
		if res then
			return res
		end
	end
	return require("telescope.actions")[key]
end

return setmetatable(M, meta)
