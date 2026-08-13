local split_path
local mappings = {}

vim = {
	tbl_deep_extend = function()
		return { args = {} }
	end,
	system = function()
		return {
			wait = function()
				return { code = 0, stdout = "/repo\n", stderr = "" }
			end,
		}
	end,
	trim = function(value)
		return value:gsub("^%s+", ""):gsub("%s+$", "")
	end,
	cmd = {
		GinDiff = function() end,
		GinBuffer = function() end,
		GinStatus = function() end,
		split = function(opts)
			split_path = opts.args[1]
		end,
	},
	treesitter = { start = function() end },
	api = {
		nvim_set_option_value = function() end,
		nvim_get_current_tabpage = function()
			return 1
		end,
		nvim_get_current_buf = function()
			return 2
		end,
		nvim_create_augroup = function()
			return 3
		end,
		nvim_create_autocmd = function() end,
	},
	keymap = {
		set = function(_, lhs, rhs)
			mappings[lhs] = rhs
		end,
	},
	fn = {
		tempname = function()
			return "/tmp/nvim/commit-123"
		end,
	},
	fs = {
		basename = function(path)
			return path:match("[^/]+$")
		end,
		joinpath = function(...)
			return table.concat({ ... }, "/")
		end,
	},
}

local commit = dofile("dot_config/nvim/lua/plugins/git/commit.lua")
commit.exec()

assert(split_path == "/repo/.commit-123.gitcommit", "commit buffer must be anchored to the repository")
