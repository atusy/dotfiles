local M = {}

local MiniStatusline = require("mini.statusline")

local function active()
	local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = math.huge })
	local filename = MiniStatusline.section_filename({ trunc_width = 140 })
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
	require("mini.statusline").setup({
		content = {
			active = active,
		},
	})
end

function M.lazy()
	vim.opt.laststatus = 0
	vim.api.nvim_create_autocmd("WinNew", {
		group = vim.api.nvim_create_augroup("atusy-mini-statusline", {}),
		callback = function()
			local cnt = 0
			for _, w in pairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_config(w).relative == "" then
					cnt = cnt + 1
					if cnt == 2 then
						break
					end
				end
			end
			if cnt < 2 then
				return
			end

			vim.opt.laststatus = 2
			M.setup()
		end,
	})
end

return M
