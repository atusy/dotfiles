local M = require("telescope.actions.mt").transform_mod({
	search_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("plugins.telescope.picker").quickfix({
			sorter = require("plugins.telescope.sorter").generic_sorter(),
		})
	end,
	--- grep on entry line
	grep_line_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("plugins.telescope.picker").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter(nil, { target = "line" }),
		})
	end,
	--- grep on entry filename
	grep_filename_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("plugins.telescope.picker").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter(nil, { target = "filename" }),
		})
	end,
	--- grep on entry text
	grep_text_in_quickfix = function(...)
		require("telescope.actions").send_to_qflist(...)
		require("plugins.telescope.picker").quickfix({
			sorter = require("plugins.telescope.sorter").regex_sorter(nil, { target = "text" }),
		})
	end,
})

local meta = getmetatable(M)
local index = meta.__index

function meta.__index(self, key)
	return index and index(self, key) or require("telescope.actions")[key]
end

return setmetatable(M, meta)
