local M = {}

local function active()
	local MiniStatusline = require("mini.statusline")
	local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = math.huge })
	local filename = MiniStatusline.section_filename({ trunc_width = math.huge }) -- prefer relative path
	local location = MiniStatusline.section_location({ trunc_width = 75 })
	local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

	return MiniStatusline.combine_groups({
		{ hl = mode_hl, strings = { mode } },
		"%<", -- Mark general truncate point
		{ hl = "MiniStatuslineFilename", strings = { filename } },
		"%=", -- End left alignment
		{ hl = mode_hl, strings = { search, location } },
	})
end

function M.setup()
	local MiniStatusline = require("mini.statusline")
	MiniStatusline.setup({
		content = {
			active = active,
			inactive = function()
				return MiniStatusline.combine_groups({
					MiniStatusline.section_filename({ trunc_width = math.huge }), -- prefer relative path
				})
			end,
		},
	})
end

function M.lazy()
	vim.opt.laststatus = 0
	local loaded = false

	-- on setup, also revert config
	local function setup()
		vim.opt.laststatus = 2
		M.setup()
		pcall(function()
			vim.keymap.del("n", "n")
			vim.keymap.del("n", "N")
		end)
	end

	-- lazy load with n/N to show search count
	vim.keymap.set("n", "n", function()
		setup()
		return "n"
	end, { expr = true })
	vim.keymap.set("n", "N", function()
		setup()
		return "N"
	end, { expr = true })

	-- lazy load with WinNew to show window status
	vim.api.nvim_create_autocmd("WinNew", {
		group = vim.api.nvim_create_augroup("atusy-mini-statusline", {}),
		callback = function()
			if loaded then
				return true
			end
			local cnt = 0
			for _, w in pairs(vim.api.nvim_tabpage_list_wins(0)) do
				if vim.api.nvim_win_get_config(w).relative == "" then
					cnt = cnt + 1
					if cnt == 2 then
						break
					end
				end
			end
			if cnt < 2 then
				return false
			end

			setup()
			return true
		end,
	})
end

return M
