local function is_win_focusable(win)
	local config = vim.api.nvim_win_get_config(win)
	return config.focusable
end

local function count_win_focusable(wins)
	return #vim.tbl_filter(is_win_focusable, wins)
end

local setup_chowcho = function()
	local safely = require("atusy.misc").safely

	require("chowcho").setup({
		use_exclude_default = false,
		exclude = function(_, _)
			return false
		end,
	})
	local run = require("chowcho").run

	local function chowcho_focus()
		-- Focues window
		if count_win_focusable(vim.api.nvim_tabpage_list_wins(0)) > 2 then
			run(safely(vim.api.nvim_set_current_win), {
				use_exclude_default = false,
				exclude = function(_, win)
					return vim.api.nvim_win_get_config(win).focusable == false
				end,
			})
		else
			vim.cmd("wincmd w")
		end
	end

	vim.keymap.set({ "", "t" }, "<C-W><C-W>", chowcho_focus)
	vim.keymap.set({ "", "t" }, "<C-W>w", chowcho_focus)

	local function _chowcho_hide()
		local nwins = #vim.api.nvim_tabpage_list_wins(0)
		if nwins == 1 and vim.api.nvim_get_current_tabpage() ~= 1 then
			vim.cmd("tabclose")
		elseif nwins == 2 then
			vim.cmd("wincmd o")
		elseif nwins > 2 then
			run(safely(vim.api.nvim_win_hide))
		end
	end

	-- vim.keymap.set({ '', 't' }, '<C-W>c', _chowcho_hide)
	vim.keymap.set({ "", "t" }, "<C-W><Space>", _chowcho_hide)
	vim.keymap.set({ "", "t" }, "<C-W><C-Space>", _chowcho_hide)

	local function _chowcho_edit()
		-- Edits buffer from the selected in the current
		if #vim.api.nvim_tabpage_list_wins(0) < 1 then
			return
		end
		run(
			safely(function(n)
				vim.api.nvim_win_set_buf(0, vim.api.nvim_win_get_buf(n))
				vim.api.nvim_win_set_cursor(0, vim.api.nvim_win_get_cursor(n))
			end),
			{
				use_exclude_default = false,
				exclude = function(_, win)
					local winconf = vim.api.nvim_win_get_config(win)
					return winconf.external or winconf.relative ~= ""
				end,
			}
		)
	end

	vim.keymap.set({ "", "t" }, "<C-W>e", _chowcho_edit)
	vim.keymap.set({ "", "t" }, "<C-W><C-E>", _chowcho_edit)

	---@param layout table returnd by vim.fn.winlayout()
	---@param cur integer of the current winid
	---@param target integer of the target winid
	---@return integer? count to be passed to wincmd x if available
	local function find_wincmd_x_target(layout, cur, target)
		if layout[1] == "leaf" then
			return
		end
		local leaves = {}
		for i, item in pairs(layout[2]) do
			if item[1] == "leaf" then
				leaves[item[2]] = i
			else
				local res = find_wincmd_x_target(item, cur, target)
				if res then
					return res
				end
			end
		end
		return leaves[cur] and leaves[target]
	end

	local function _chowcho_exchange()
		-- Swaps buffers between windows
		-- also moves between windows to apply styler.nvim theming
		if #vim.api.nvim_tabpage_list_wins(0) <= 2 then
			vim.cmd("wincmd x")
			return
		end
		run(
			safely(function(n)
				local cur = vim.api.nvim_get_current_win()
				if n == cur then
					return
				end
				local count = find_wincmd_x_target(vim.fn.winlayout(), cur, n)
				if count then
					vim.cmd(count .. "wincmd x")
					return
				end
				local bufnr0 = vim.api.nvim_win_get_buf(cur)
				local bufnrn = vim.api.nvim_win_get_buf(n)
				vim.api.nvim_win_set_buf(cur, bufnrn)
				vim.api.nvim_win_set_buf(n, bufnr0)
			end),
			{
				use_exclude_default = false,
				exclude = function(_, win)
					local winconf = vim.api.nvim_win_get_config(win)
					return winconf.external or winconf.relative ~= ""
				end,
			}
		)
	end

	vim.keymap.set({ "", "t" }, "<C-W><C-X>", _chowcho_exchange)
	vim.keymap.set({ "", "t" }, "<C-W>x", _chowcho_exchange)
end

return {
	{
		"https://github.com/tkmpypy/chowcho.nvim",
		event = "WinNew",
		config = setup_chowcho,
	},
}
