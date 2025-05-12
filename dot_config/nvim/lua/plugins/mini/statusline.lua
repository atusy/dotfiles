local M = {}

local macro_register = nil

local function on_macro_recording(ctx)
	if vim.o.cmdheight > 0 then
		-- register is shown in cmdline
		return
	end
	macro_register = vim.fn.reg_recording()
	vim.api.nvim_create_autocmd("RecordingLeave", {
		group = ctx and ctx.group or vim.api.nvim_create_augroup("atusy-mini-statusline-recording-leave", {}),
		callback = function()
			macro_register = nil
		end,
	})
end

local function make_active_statusline()
	local MiniStatusline = require("mini.statusline")
	local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = math.huge })
	local filename = MiniStatusline.section_filename({ trunc_width = math.huge }) -- prefer relative path
	local location = MiniStatusline.section_location({ trunc_width = 75 })
	local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

	return MiniStatusline.combine_groups({
		{ hl = "MiniStatuslineDevinfo", strings = { macro_register } },
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
			active = make_active_statusline,
			inactive = function()
				return MiniStatusline.combine_groups({
					MiniStatusline.section_filename({ trunc_width = math.huge }), -- prefer relative path
				})
			end,
		},
	})

	vim.api.nvim_create_autocmd("RecordingEnter", {
		group = vim.api.nvim_create_augroup("atusy-mini-statusline-recording", {}),
		callback = on_macro_recording,
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
		loaded = true
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
	vim.api.nvim_create_autocmd({ "WinNew", "RecordingEnter" }, {
		group = vim.api.nvim_create_augroup("atusy-mini-statusline", {}),
		callback = function(ctx)
			if loaded then
				return true
			end

			if ctx.event == "RecordingEnter" and vim.o.cmdheight == 0 then
				on_macro_recording()
				setup()
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
