local L = {}

function L.select(finder, open)
	local entry = finder:cursor_node_entry()
	if entry:isdir() then
		finder:exec_action("n_select")
		return
	end
	(open or vim.cmd.edit)(vim.fn.fnameescape(entry.path))
end

function L.yank_path(finder, absolute, reg)
	reg = reg or vim.v.register or '"'
	local entry = finder:cursor_node_entry()
	if absolute then
		vim.fn.setreg(reg, entry.path)
	else
		vim.fn.setreg(reg, vim.fn.fnamemodify(entry.path, ":."))
	end
end

local M = {
	gK = function(finder)
		vim.print(finder)
	end,
	K = function(finder)
		local entry = finder:cursor_node_entry()
		vim.print(entry)
	end,
	["<c-s>"] = function(finder)
		finder:synchronize()
	end,
	["#"] = function()
		local altbuf = vim.fn.expand("#")
		require("fyler").navigate(vim.fn.filereadable(altbuf) == 1 and altbuf or nil)
	end,
	["zc"] = "CollapseNode",
	["zM"] = "CollapseAll",

	--[[yank path variants]]
	["yap"] = function(finder)
		L.yank_path(finder, true, nil)
	end,
	["yrp"] = function(finder)
		L.yank_path(finder, false, nil)
	end,
	["gyap"] = function(finder)
		L.yank_path(finder, true, "+")
	end,
	["gyrp"] = function(finder)
		L.yank_path(finder, false, "+")
	end,

	--[[select variants]]
	--- select normally to open/close a directory or edit a file
	---
	--- or edit in a new window with preceeding <c-w>s or <c-w>v
	gf = function(finder)
		L.select(finder)
	end,
	--- select like *CTRL-W_gf*
	["<c-w>gf"] = function(finder)
		L.select(finder, vim.cmd.tabedit)
	end,
	--- select and edit in a selected window using *chowcho*
	["<cr>"] = function(finder)
		local function chowcho(file)
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
		L.select(finder, chowcho)
	end,
	--- select and open file externally
	["gx"] = function(finder)
		local entry = finder:cursor_node_entry()
		vim.ui.open(entry.path)
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
