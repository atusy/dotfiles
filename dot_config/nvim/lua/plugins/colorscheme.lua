-- const
local ACTIVE_COLORSCHEME = "duskfox" -- for the active buffer the first tabpage
local INACTIVE_COLORSCHEME = "nordfox"
local OUTSIDE_COLORSCHEME = "carbonfox"
local TAB_COLORSCHEME = "terafox" -- for the active buffer in the other tabpages

local function likely_cwd(buf)
	buf = buf or vim.api.nvim_win_get_buf(0)
	if vim.bo[buf].buftype ~= "" then
		return true
	end

	local file = vim.api.nvim_buf_get_name(buf)
	return file == "" or require("atusy.misc").in_cwd(file)
end

local function set_theme(win, colorscheme)
	if colorscheme == vim.g.colors_name then
		-- if default colorscheme, clear() should be enough
		require("styler").clear(win)
	elseif colorscheme ~= (vim.w[win].theme or {}).colorscheme then
		require("styler").set_theme(win, { colorscheme = colorscheme })
	end
end

local function theme_active_win(win, tab)
	-- use default colorscheme on floating windows
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return
	end

	-- apply colorscheme
	local COLORSCHEME = ACTIVE_COLORSCHEME
	if tab ~= 1 then
		COLORSCHEME = TAB_COLORSCHEME
	elseif not likely_cwd(vim.api.nvim_win_get_buf(win)) then
		COLORSCHEME = OUTSIDE_COLORSCHEME
	end
	set_theme(win, COLORSCHEME)
end

local function theme_inactive_win(win, tab)
	-- skip for certain situations
	if not vim.api.nvim_win_is_valid(win) then
		return
	end
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return
	end

	-- apply colorscheme
	local COLORSCHEME = INACTIVE_COLORSCHEME
	if tab == 1 and not likely_cwd(vim.api.nvim_win_get_buf(win)) then
		COLORSCHEME = OUTSIDE_COLORSCHEME
	end
	set_theme(win, COLORSCHEME)
end

local function theme()
	local win_cursor = vim.api.nvim_get_current_win()
	local tab = vim.api.nvim_get_current_tabpage()

	-- Activate
	theme_active_win(win_cursor, tab)

	for _, w in pairs(vim.api.nvim_tabpage_list_wins(tab)) do
		if w ~= win_cursor then
			theme_inactive_win(w, tab)
		end
	end

	-- redraw is required for instant theming on CmdlineEnter
	-- after closing of focused floating windows,
	vim.cmd([[redraw]])
end

local state = {}

local function set_styler()
	vim.api.nvim_create_autocmd({
		"BufWinEnter", -- instead of BufEnter
		"WinEnter",
		"WinLeave", -- supports changes without WinEnter (e.g., cmdbuf.nvim)
		"WinNew", -- supports new windows without focus (e.g., `vim.api.nvim_win_call(0, vim.cmd.vsplit)`)
		"WinClosed", --[[
        supports active window being closed via win_call
            ``` vim
            vsplit
            lua (function(w) vim.api.nvim_win_call(vim.fn.win_getid(vim.fn.winnr('#')), function() vim.api.nvim_win_close(w, true) end) end)(vim.api.nvim_get_current_win())
            ```
      ]]
	}, {
		group = vim.api.nvim_create_augroup("atusy.styler", {}),
		callback = function()
			-- only apply theme from the latest schedule
			for k, _ in pairs(state) do
				state[k] = nil
			end
			local key = tostring(math.random())
			state[key] = true
			vim.schedule(function()
				if state[key] then
					theme()
					-- require("atusy.highlight").change_background(require("atusy.highlight").transparent)
				end
			end)
		end,
	})
end

return {
	{
		"https://github.com/RRethy/vim-illuminate",
		lazy = true,
		event = { "CursorHold" },
		init = function()
			vim.keymap.set("n", "<Left>", [[<Cmd>lua require("illuminate").goto_prev_reference()<CR>]])
			vim.keymap.set("n", "<Right>", [[<Cmd>lua require("illuminate").goto_next_reference()<CR>]])
		end,
		config = function()
			local function hi()
				-- @illuminate is defined on configure of treesitter
				vim.api.nvim_set_hl(0, "IlluminatedWordText", { link = "@illuminate" })
				vim.api.nvim_set_hl(0, "IlluminatedWordRead", { link = "@illuminate" })
				vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { link = "@illuminate" })
			end

			require("illuminate").configure({ modes_allowlist = { "n" } })
			vim.api.nvim_create_autocmd(
				"ColorScheme",
				{ group = vim.api.nvim_create_augroup("atusy.illuminate", {}), callback = hi }
			)
			hi()
		end,
	},
	{
		"https://github.com/uga-rosa/ccc.nvim",
		-- migrated from https://github.com/norcalli/nvim-colorizer.lua
		-- because colorizer's extmark are vulnerable to text editing
		-- For example, extmark apparently disappears when `i#123456<Esc>O`
		lazy = true,
		event = "BufReadPost",
		config = function()
			require("ccc").setup({
				highlighter = {
					auto_enable = true,
					lsp = true,
				},
			})
		end,
	},
	{
		"https://github.com/folke/styler.nvim",
		event = { "WinNew", "BufRead", "BufNewFile" },
		dependencies = { "https://github.com/EdenEast/nightfox.nvim" },
		config = function()
			set_styler()
		end,
	},
	{
		"https://github.com/EdenEast/nightfox.nvim",
		lazy = false,
		priority = 9999,
		config = function()
			require("nightfox").setup({
				groups = {
					all = {
						["@text.literal"] = { link = "String" },
						NvimTreeNormal = { link = "Normal" },
					},
				},
				options = { inverse = { visual = true } },
			})
			vim.cmd.colorscheme("duskfox")
			-- NOTE: disable it because of strange behavior on opening telescope right after VimEnter
			-- vim.schedule(function()
			-- 	if vim.env.NVIM_TRANSPARENT == "1" then
			-- 		require("atusy.highlight").remove_background(0)
			-- 	end
			-- end)
		end,
	},
}
