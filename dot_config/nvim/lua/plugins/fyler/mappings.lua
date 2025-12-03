---Select the current entry and toggle directory or open file
---@param finder table
---@param open function(string)
local function select_entry(finder, open)
	local entry = finder:cursor_node_entry()
	if entry:is_directory() then
		finder:exec_action("n_select")
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

local M = {
	["<C-S>"] = function(finder)
		finder:synchronize()
	end,
	["#"] = function()
		local altbuf = vim.fn.expand("#")
		require("fyler").navigate(vim.fn.filereadable(altbuf) == 1 and altbuf or nil)
	end,
	zc = "CollapseNode",
	zM = "CollapseAll",

	--[[yank path variants]]
	yp = function(finder)
		vim.fn.setreg(vim.v.register, finder:cursor_node_entry().path)
	end,
	yr = function(finder)
		vim.fn.setreg(vim.v.register, vim.fn.fnamemodify(finder:cursor_node_entry().path, ":."))
	end,

	--[[select variants]]
	gf = function(finder)
		select_entry(finder, vim.cmd.edit) -- to open in a new window, preceed with <C-W>s or <C-W>v
	end,
	["<C-W>gf"] = function(finder)
		select_entry(finder, vim.cmd.tabedit) -- opens file like *CTRL-W_gf* opens in a new tab
	end,
	["<cr>"] = function(finder)
		select_entry(finder, open_with_chowcho)
	end,
	gx = function(finder)
		vim.ui.open(finder:cursor_node_entry().path)
	end,

	--[[debugging]]
	gK = function(finder)
		vim.print(finder)
	end,
	K = function(finder)
		vim.print(finder:cursor_node_entry())
	end,

	--[[disabled defaults]]
	q = false,
	["<C-t>"] = false,
	["|"] = false,
	["-"] = false,
	["^"] = false,
	["="] = false,
	["."] = false,
	["<BS>"] = false,
}

return M
