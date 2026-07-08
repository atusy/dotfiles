---@param instance table
---@return table|nil
local function cursor_entry(instance)
	return require("fyler.finder").parse_cursor_line(instance)
end

---Select the current entry and toggle directory or open file.
---@param instance table
---@param open function(string)
local function select_entry(instance, open)
	local entry = cursor_entry(instance)
	if not entry then
		return
	end

	if entry.type == "directory" then
		instance:select()
		return
	end
	open(vim.fn.fnameescape(entry.path))
end

---@param file string
local function open_with_chowcho(file)
	require("chowcho").run(function(n)
		vim.api.nvim_win_call(n, function()
			vim.cmd.edit(file)
		end)
		vim.api.nvim_set_current_win(n)
	end, {
		use_exclude_default = false,
		exclude = function(_, win)
			local winconf = vim.api.nvim_win_get_config(win)
			return winconf.external or winconf.relative ~= ""
		end,
	})
end

local navigation = nil
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
	callback = function(ev)
		local bufname = vim.api.nvim_buf_get_name(0)
		if ev.event == "BufWinEnter" and ev.file ~= bufname then
			return
		end

		vim.uv.fs_stat(bufname, function(err)
			if not err then
				navigation = bufname
			end
		end)
	end,
})

local M = {
	n = {
		["<C-S>"] = {
			action = "mutate",
		},
		["<F5>"] = {
			action = "refresh",
			args = { force = true, recursive = true },
		},
		["#"] = {
			action = function(instance)
				if navigation then
					instance:follow({ target_path = navigation, force = true })
				end
			end,
		},
		zc = {
			action = "shrink",
		},
		zM = {
			action = function(instance)
				local libpath = require("fyler.lib.path")
				local root_key = libpath.to_key(instance.state.pseudo_root_path)
				for key in pairs(instance.state.meta) do
					instance.state.meta[key] = key == root_key
				end
				instance:refresh()
			end,
		},

		-- yank path variants
		yp = {
			action = function(instance)
				local entry = cursor_entry(instance)
				if entry then
					vim.fn.setreg(vim.v.register, entry.path)
				end
			end,
		},
		yr = {
			action = function(instance)
				local entry = cursor_entry(instance)
				if entry then
					vim.fn.setreg(vim.v.register, vim.fn.fnamemodify(entry.path, ":."))
				end
			end,
		},

		-- select variants
		gf = {
			action = function(instance)
				select_entry(instance, vim.cmd.edit) -- to open in a new window, precede with <C-W>s or <C-W>v
			end,
		},
		["<C-W>gf"] = {
			action = function(instance)
				select_entry(instance, vim.cmd.tabedit) -- opens file like *CTRL-W_gf* opens in a new tab
			end,
		},
		["<CR>"] = {
			action = function(instance)
				select_entry(instance, open_with_chowcho)
			end,
		},
		gx = {
			action = function(instance)
				local entry = cursor_entry(instance)
				if entry then
					vim.ui.open(entry.path)
				end
			end,
		},

		-- debugging
		gK = {
			action = function(instance)
				vim.print(instance)
			end,
		},
		K = {
			action = function(instance)
				vim.print(cursor_entry(instance))
			end,
		},

		-- disabled defaults
		q = { disabled = true },
		["<C-t>"] = { disabled = true },
		["|"] = { disabled = true },
		["-"] = { disabled = true },
		["^"] = { disabled = true },
		["="] = { disabled = true },
		["."] = { disabled = true },
		["<BS>"] = { disabled = true },
	},
}

return M
