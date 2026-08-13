local split_path
local mappings = {}
local system_calls = {}

local fake_vim = {
	tbl_deep_extend = function()
		return { args = {} }
	end,
	system = function(command, opts)
		table.insert(system_calls, { command = command, opts = opts })
		return {
			wait = function()
				return { code = 0, stdout = command[2] == "rev-parse" and "/repo\n" or "", stderr = "" }
			end,
		}
	end,
	schedule = function() end,
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
		nvim_buf_get_lines = function()
			return { "feat: message" }
		end,
		nvim_buf_set_lines = function() end,
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

local chunk = assert(loadfile("dot_config/nvim/lua/plugins/git/commit.lua"))
setfenv(chunk, setmetatable({ vim = fake_vim }, { __index = _G }))
local commit = chunk()
commit.exec()

assert(split_path == "/repo/.commit-123.gitcommit", "commit buffer must be anchored to the repository")

mappings["<Plug>(C-S)<C-Q>"]()
assert(system_calls[2].opts.cwd == "/repo", "git commit must use the captured repository root")

mappings["<C-O>"]()
assert((system_calls[3].opts or {}).cwd == "/repo", "git log must use the captured repository root")
