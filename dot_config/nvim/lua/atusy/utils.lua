local M = {}

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
