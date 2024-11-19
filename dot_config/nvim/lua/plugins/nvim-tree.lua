local function tree_reveal()
	require("nvim-tree.api").tree.find_file(vim.fn.bufname(vim.fn.winbufnr(vim.fn.winnr("#"))))
end

local function node_open_edit()
	local p = require("nvim-tree.api").tree.get_node_under_cursor().absolute_path
	local has_chowcho, chowcho = pcall(require, "chowcho")
	local nwins = #vim.api.nvim_tabpage_list_wins(0)
	if (nwins <= 2) or (vim.fn.isdirectory(p) == 1) or not has_chowcho then
		require("nvim-tree.api").node.open.edit()
		return
	end
	chowcho.run(function(w)
		vim.api.nvim_set_current_win(w)
		vim.cmd.edit(p)
	end, {
		exclude = function(buf, win)
			local ft = vim.bo[buf].filetype
			if ft == "NvimTree" then
				return true
			end

			local winconf = vim.api.nvim_win_get_config(win)
			if winconf.external or winconf.relative ~= "" or not winconf.focusable then
				return true
			end

			return false
		end,
	})
end

local function node_open_system()
	local row = vim.api.nvim_win_get_cursor(0)
	if row == 1 then
		vim.ui.open(require("nvim-tree.api").tree.get_nodes().absolute_path)
	else
		require("nvim-tree.api").node.run.system()
	end
end

local function fs_copy()
	local list = require("nvim-tree.api").marks.list()
	if #list > 0 then
		require("nvim-tree.api").fs.clear_clipboard()
		for _, node in pairs(list) do
			require("nvim-tree.api").fs.copy.node(node)
		end
	else
		require("nvim-tree.api").fs.copy.node()
	end
end

local function fs_cut()
	local list = require("nvim-tree.api").marks.list()
	if #list > 0 then
		require("nvim-tree.api").fs.clear_clipboard()
		for _, node in pairs(list) do
			require("nvim-tree.api").fs.cut(node)
		end
	else
		require("nvim-tree.api").fs.cut()
	end
end

local function fs_trash()
	local bufremove = (function()
		local ok, _ = pcall(require, "mini.bufremove")
		if ok then
			return function(buf)
				require("mini.bufremove").delete(buf, true)
			end
		end
		return function(buf)
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end)()

	local marks = require("nvim-tree.api").marks.list()
	if #marks > 0 then
		for _, buf in pairs(vim.api.nvim_list_bufs()) do
			for _, mark in pairs(marks) do
				if vim.api.nvim_buf_get_name(buf) == mark.absolute_path then
					bufremove(buf)
				end
			end
		end
		require("nvim-tree.api").marks.bulk.trash()
	end

	local path = require("nvim-tree.api").tree.get_node_under_cursor().absolute_path
	for _, buf in pairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf) == path then
			bufremove(buf)
		end
	end
	require("nvim-tree.api").fs.trash()
end

return {
	{
		"https://github.com/nvim-tree/nvim-tree.lua",
		lazy = true,
		init = function()
			vim.keymap.set("n", "S", [[<Cmd>lua require("nvim-tree.api").tree.open()<CR>]])
		end,
		config = function()
			pcall(require, "dressing")
			require("nvim-web-devicons")
			require("nvim-tree").setup({
				git = { ignore = false },
				renderer = { icons = { show = { git = false } } },
				on_attach = function(buffer)
					local default_text = "★ "
					vim.b[buffer].telescope_keymaps_default_text = default_text
					local function nmap(lhs, rhs, desc)
						vim.keymap.set(
							"n",
							lhs,
							rhs,
							{ desc = desc and (default_text .. " " .. desc), buffer = buffer }
						)
					end

					-- tree
					nmap("S", "<Cmd>NvimTreeClose<CR>")
					nmap("!", require("nvim-tree.api").tree.toggle_hidden_filter, "tree: toggle hidden")
					nmap("#", tree_reveal, "tree: reveal")
					nmap("<C-R>", "<Cmd>NvimTreeRefresh<CR>", "tree: refresh")
					nmap(
						"0",
						[[<Cmd>lua require("nvim-tree.api").tree.change_root(".")<CR>]],
						"tree: change root to cwd"
					)
					nmap("cd", function()
						local row = vim.require("nvim-tree.api").nvim_win_get_cursor(0)
						if row == 1 then
							require("nvim-tree.api").tree.change_root("..")
						else
							require("nvim-tree.api").tree.change_root_to_node()
						end
					end)

					-- node
					nmap("h", require("nvim-tree.api").node.navigate.parent_close, "node: close the parent")
					nmap("l", require("nvim-tree.api").node.open.no_window_picker, "node: open in the previous window")
					nmap("gx", node_open_system, "node: run system")
					nmap("K", require("nvim-tree.api").node.show_info_popup, "node: info")
					nmap("<CR>", node_open_edit, "node: open in a chosen window")
					nmap("<C-W><C-V>", require("nvim-tree.api").node.open.vertical, "node: open in a vertical split")
					nmap(
						"<C-W><C-S>",
						require("nvim-tree.api").node.open.horizontal,
						"node: open in a horizontal split"
					)

					-- file manipulations
					nmap("a", require("nvim-tree.api").fs.create, "fs: add")
					nmap(" r", require("nvim-tree.api").fs.rename_full, "fs: rename")
					nmap(
						"p",
						require("nvim-tree.api").fs.paste,
						"fs: paste as a child of directory or as a sibling of file under the cursor"
					)
					nmap("P", function()
						-- paste file to the parent directory of the cursor node
						local cursor = require("nvim-tree.api").tree.get_node_under_cursor()
						require("nvim-tree.api").fs.paste(cursor.parent)
					end, "fs: paste as a child of the parent directory of the cursor node")
					nmap("d", "<Nop>")
					nmap("dd", fs_cut, "fs: cut")
					nmap("D", fs_trash, "fs: trash")
					nmap("y", "<Nop>")
					nmap("yy", fs_copy, "fs: copy")
					nmap("ya", require("nvim-tree.api").fs.copy.absolute_path, "fs: clipboard absolute path")
					nmap("yr", require("nvim-tree.api").fs.copy.relative_path, "fs: clipboard relative path")
					nmap("_", require("nvim-tree.api").fs.clear_clipboard, "fs: clear clipboard") -- _ comes from blackhole...
					nmap("+", require("nvim-tree.api").fs.clear_clipboard, "fs: print clipboard") -- + comes from unnamedplus

					-- else
					nmap("f", require("nvim-tree.api").live_filter.start, "live filter: start")
					nmap("m", require("nvim-tree.api").marks.toggle, "mark: toggle")
					nmap("M", require("nvim-tree.api").marks.clear, "mark: clear")
					nmap("<C-Right>", [[<Cmd>NvimTreeResize +2<CR>]], "ui: larger")
					nmap("<C-Left>", [[<Cmd>NvimTreeResize -2<CR>]], "ui: smaller")
				end,
			})
		end,
	},
}
