local target = vim.fn.tempname()
vim.fn.writefile({ "selected" }, target)

local instance = {
	win_id = vim.api.nvim_get_current_win(),
}
local finder_closed = false

function instance:close()
	finder_closed = true
end

package.preload["fyler.finder"] = function()
	return {
		parse_cursor_line = function()
			return { type = "file", path = target }
		end,
	}
end

package.preload["chowcho"] = function()
	return {
		run = function(callback)
			callback(instance.win_id)
		end,
	}
end

local mappings = dofile("dot_config/nvim/lua/plugins/fyler/mappings.lua")
mappings.n["<CR>"].action(instance)

assert(finder_closed, "selecting the Fyler window must close the finder before editing")
assert(vim.api.nvim_buf_get_name(0) == vim.uv.fs_realpath(target), "the selected file must be open")
