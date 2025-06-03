-- [[ helpers ]]
local augroup = vim.api.nvim_create_augroup("atusy", {})

--[[ options ]]
-- global
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.diffopt:append("algorithm:histogram")
vim.opt.exrc = true
vim.opt.grepprg = [[rg --glob '!.git' --hidden --vimgrep --follow $*]]
vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }
vim.opt.guicursor = {
	[[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
	[[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
	[[sm:block-blinkwait175-blinkoff150-blinkon175]],
}
vim.opt.ignorecase = true
vim.opt.isfname:append([[?]])
vim.opt.matchtime = 1
vim.opt.mouse = "a"
vim.opt.pumheight = 10
vim.opt.pumblend = 25
vim.opt.showmode = false
vim.opt.smoothscroll = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.wildoptions:append("fuzzy")
vim.opt.tabclose = "uselast,left"

-- window
vim.opt.signcolumn = "yes"
vim.opt.breakindent = true
vim.opt.cursorline = true
vim.opt.fillchars = "eob: "
vim.opt.foldtext = [[v:lua.require("atusy.fold").foldtext()]]
vim.opt.list = true
vim.opt.listchars = {
	tab = "▸▹┊",
	trail = "▫",
	extends = "»",
	precedes = "«",
}
vim.opt.smoothscroll = true
vim.opt.virtualedit = "block"
vim.opt.winblend = 25

-- buffer
vim.opt.autoread = true
vim.opt.copyindent = true
vim.opt.expandtab = true
vim.opt.matchpairs:append(
	[[<:>,「:」,（:）,『:』,【:】,《:》,〈:〉,｛:｝,［:］,【:】,‘:’,“:”]]
)
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- cmdline
local ok, extui = pcall(require, "vim._extui")
if ok then
	vim.opt.cmdheight = 0
	extui.enable({
		enable = true,
		msg = {
			pos = "box",
			box = { timeout = 5000 },
		},
	})
	vim.keymap.set("n", "<c-l>", function()
		local extui_cleared, err = pcall(function()
			local wins = require("vim._extui.shared").wins[vim.api.nvim_get_current_tabpage()]
			local bufs = require("vim._extui.shared").bufs
			vim.api.nvim_win_set_config(wins.box, { hide = true })
			vim.schedule(function()
				vim.api.nvim_buf_set_lines(bufs.cmd, 0, -1, false, {})
			end)
		end)
		if not extui_cleared and err then
			vim.notify(err, vim.log.levels.ERROR)
		end
		return "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>"
	end, { expr = true })
end

--[[ commands ]]
vim.api.nvim_create_user_command("W", "write !sudo tee % >/dev/null", {})

--[[ mappings ]]
vim.g.mapleader = " "
vim.keymap.set({ "n", "x" }, "s", "<plug>(s)") -- be prefix for sandwich and fuzzy finders
vim.keymap.set("n", "<C-G>", "<Cmd>lua if vim.o.laststatus == 0 then vim.cmd.f() end<CR><Plug>(C-G)")
vim.keymap.set("n", "<Plug>(C-G)<C-G>", '<Cmd>let @+ = expand("%:~:.")<CR>')
vim.keymap.set("n", "<Plug>(C-G)g", '<Cmd>let @+ = expand("%:~")<CR>')
vim.keymap.set("n", "H", "H<Plug>(H)")
vim.keymap.set("n", "<Plug>(H)H", "<PageUp>H<Plug>(H)")
vim.keymap.set("n", "L", "L<Plug>(L)")
vim.keymap.set("n", "<Plug>(L)L", "<PageDown>Lzb<Plug>(L)")
vim.keymap.set("x", "<C-G>", "<Plug>(C-G)")
vim.keymap.set("x", "<Plug>(C-G)<C-G>", "<C-G>")
vim.keymap.set("c", "<C-A>", "<Home>")
vim.keymap.set("t", "<C-W>", [[<C-\><C-N><C-W>]])
vim.keymap.set({ "", "!", "t" }, [[<C-\>]], [[<C-\><C-N>]], { nowait = true })
vim.keymap.set("x", "zf", [[mode() ==# 'V' ? 'zf' : 'Vzf']], { expr = true })
vim.keymap.set("x", " ue", [[<Cmd>lua require("atusy.misc").urlencode()<CR>]])
vim.keymap.set("x", " ud", [[<Cmd>lua require("atusy.misc").urldecode()<CR>]])
vim.keymap.set({ "n", "x" }, "gf", [[<Cmd>lua require("atusy.misc").open_cfile()<CR>]])
vim.keymap.set({ "n", "x" }, "<C-W><C-F>", [[<Cmd>lua require("atusy.misc").open_cfile({ cmd = "vs" })<CR>]])

-- mappings: extui
---@param defer_revert number | nil
local function toggle_cmdheight(defer_revert)
	if vim.o.laststatus > 0 then
		-- show index in statusline
		return
	end
	if require("vim._extui.shared").cfg.enable then
		vim.o.cmdheight = 1
		local group = vim.api.nvim_create_augroup("atusy.n", { clear = true })
		vim.api.nvim_create_autocmd("CursorHold", {
			group = group,
			callback = function(ctx)
				vim.defer_fn(function()
					local autocmds = vim.api.nvim_get_autocmds({ group = group })
					for _, autocmd in ipairs(autocmds) do
						if autocmd.id == ctx.id then
							vim.o.cmdheight = 0
							return
						end
					end
					pcall(vim.api.nvim_del_autoccmd, ctx.id)
				end, defer_revert or 5000)
			end,
		})
	end
end
vim.keymap.set("n", "n", function()
	toggle_cmdheight()
	return "n"
end, { expr = true, desc = "show index of match" })
vim.keymap.set("n", "N", function()
	toggle_cmdheight()
	return "N"
end, { expr = true, desc = "show index of match" })

-- mappings: window management
vim.keymap.set("n", "<C-W><C-V>", "<C-W><C-V><Cmd>horizontal wincmd =<CR>")
vim.keymap.set("n", "<C-W><C-S>", "<C-W><C-S><Cmd>vertical wincmd =<CR>")
if vim.env.WEZTERM_PANE ~= nil then
	local directions = { h = "Left", j = "Down", k = "Up", l = "Right" }
	local function move_nvim_win_or_wezterm_pane(hjkl)
		local win = vim.api.nvim_get_current_win()
		vim.cmd.wincmd(hjkl)
		if win == vim.api.nvim_get_current_win() then
			vim.system({ "wezterm", "cli", "activate-pane-direction", directions[hjkl] })
		end
	end
	for k, _ in pairs(directions) do
		vim.keymap.set("n", "<c-w>" .. k, function()
			move_nvim_win_or_wezterm_pane(k)
		end)
	end
end

-- mappings: tab management
-- continue moving around tab (e.g., gtttT gTtT)
vim.keymap.set("n", "gt", "gt<Plug>(gt)")
vim.keymap.set("n", "gT", "gT<Plug>(gt)")
vim.keymap.set("n", "<Plug>(gt)t", "gt<Plug>(gt)")
vim.keymap.set("n", "<Plug>(gt)T", "gT<Plug>(gt)")

-- mappings: diagnostics
vim.keymap.set("n", "<space>d", [[<Cmd>lua vim.diagnostic.open_float({border = "single"})<CR>]])

-- mappings: insert-mode horizontal moves in the current undo block
vim.keymap.set("i", "<Left>", "<C-G>U<Left>")
vim.keymap.set("i", "<Right>", "<C-G>U<Right>")

-- mappings: registers and marks
vim.keymap.set({ "n", "x" }, "-", '"_')
vim.keymap.set({ "n", "x" }, "x", '"xx')
vim.keymap.set({ "n", "x" }, "X", '"xX')
vim.keymap.set({ "n", "x" }, "gy", '"+y')
vim.keymap.set({ "n", "x" }, "gY", '"+Y')
vim.keymap.set("n", "p", "pmp")
vim.keymap.set("x", "p", "Pmp") -- intentionally swap p and P
vim.keymap.set("n", "P", "Pmp")
vim.keymap.set("x", "P", "pmp") -- intentionally swap P and p
vim.keymap.set("n", "u", "umu")
vim.keymap.set("n", "<C-R>", "<C-R>mu")

-- mappings: textobj
-- vim.keymap.set({ "o", "x" }, "ii", "2i") -- ii' selects 'foo' without outer spaces (:h v_i)
vim.keymap.set({ "o", "x" }, "ii", ":<c-u>keepjumps normal! g_v^<cr>", { silent = true })
vim.keymap.set({ "o", "x" }, "ae", ":<c-u>keepjumps normal! G$vgo<cr>", { silent = true })

-- mappings: mouse
vim.keymap.set("!", "<LeftMouse>", "<Esc><LeftMouse>")
vim.keymap.set("n", "<2-LeftMouse>", "gf", { remap = true })
vim.keymap.set("n", "<LeftDrag>", "<Nop>")
vim.keymap.set("n", "<LeftRelease>", "<Nop>")

-- mappings: jumplist
vim.keymap.set("n", "g<C-O>", function()
	return require("atusy.misc").jump_file(false)
end, { expr = true })
vim.keymap.set("n", "g<C-I>", function()
	return require("atusy.misc").jump_file(true)
end, { expr = true })

-- mappings: save and ...
vim.keymap.set({ "n", "x" }, "<Plug>(save)", function()
	---@diagnostic disable-next-line: undefined-field
	local nm = vim.api.nvim_buf_get_name(0)
	for _, prefix in ipairs({ "term://" }) do
		if nm:sub(1, #prefix) == prefix then
			return
		end
	end
	for _, prefix in ipairs({ "ginedit://" }) do
		if nm:sub(1, #prefix) == prefix then
			vim.cmd.w()
			return
		end
	end
	vim.cmd((vim.uv.fs_stat(nm) and "up" or "write ++p") .. " | redraw")
end)
vim.keymap.set({ "i", "n" }, "<C-S>", [[<C-\><C-N><Plug>(save)<Plug>(C-S)]], { desc = "save" })
vim.keymap.set("n", "<Plug>(C-S)<C-A>", "<cmd>wa<cr>", { desc = "save all" })
vim.keymap.set("n", "<Plug>(C-S)<C-Q>", "<cmd>q<cr>", { desc = "save and quit" })
vim.keymap.set("n", "<Plug>(C-S)<C-M>", function()
	local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
	local bufext = bufname:gsub(".*%.", "")
	if bufext ~= "vim" and bufext ~= "lua" then
		vim.notify("Cannot source: " .. bufname, vim.log.levels.ERROR)
		return
	end
	return ":source %" -- without <CR> to confirm manually
end, { expr = true, desc = "save and source" })

-- mappings: window
local function win_move_or_cmd(row, col, cmd)
	if not require("atusy.misc").move_floatwin(row, col) then
		vim.cmd("wincmd " .. cmd)
	end
end

vim.keymap.set({ "", "t" }, "<S-Up>", function()
	win_move_or_cmd(-1, 0, "2+")
end)
vim.keymap.set({ "", "t" }, "<S-Down>", function()
	win_move_or_cmd(1, 0, "2-")
end)
vim.keymap.set({ "", "t" }, "<S-Right>", function()
	win_move_or_cmd(0, 2, "2>")
end)
vim.keymap.set({ "", "t" }, "<S-Left>", function()
	win_move_or_cmd(0, -2, "2<")
end)

-- mappings: macro
-- disable macro a-z except q on normal mode and entirely on visual mode
vim.keymap.set("x", "q", "<Nop>")
vim.keymap.set("n", "q", function()
	return vim.fn.reg_recording() == "" and "<Plug>(q)" or "q"
end, { expr = true })
vim.keymap.set("n", "<Plug>(q)q", "qq")
vim.keymap.set("n", "<Plug>(q):", "q:")
vim.keymap.set("n", "<Plug>(q)/", "q/")
vim.keymap.set("n", "<Plug>(q)?", "q?")

--[[ autocmd ]]
vim.api.nvim_create_autocmd("TermOpen", { pattern = "*", group = augroup, command = "startinsert" })

vim.api.nvim_create_autocmd("ModeChanged", {
	pattern = "c:*",
	group = augroup,
	desc = "cleanup cmdline history which are short enough or prefixed by space",
	callback = function()
		local hist = vim.fn.histget(":", -1)
		if not hist then
			return
		end
		if
			hist:match("^[a-zA-Z]+$")
			or hist:match("^..?!?$")
			or hist:match("^wqa!?$")
			or hist == "source %"
			or hist:sub(0, 1) == " "
		then
			vim.fn.histdel(":", -1)
		end
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	desc = "Toggle cursorline on InsertEnter/Leave iff cursorline is set on normal mode",
	group = augroup,
	callback = function()
		local win = vim.api.nvim_get_current_win()
		local wo = vim.wo[win]
		if not wo.cursorline then
			return
		end
		wo.cursorline = false
		vim.api.nvim_create_autocmd("ModeChanged", {
			-- InsertLeave is not adequate because <C-C> won't trigger it
			pattern = "i:*",
			once = true,
			group = vim.api.nvim_create_augroup("toggle-cursorline", {}),
			callback = function()
				pcall(vim.api.nvim_set_option_value, "cursorline", true, { win = win })
			end,
		})
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup,
	callback = function(ctx)
		local op = vim.v.event.operator
		if not op then
			return
		end

		local regname = vim.v.event.regname

		-- copy unnamed regsiter to contextful register
		-- i.e., change to c, delete to d, and yank to y
		-- note that `x` is treated as delete, not x.
		-- I map `x` and `X` register to `x`-register.
		if regname == "" then
			vim.fn.setreg(op, vim.fn.getreg())
		end

		-- set mark for the yanked region
		-- to distinguish x and d, use `x`-mark for `x`-operator
		local win = vim.api.nvim_get_current_win()
		vim.schedule(function()
			-- Do lazily to avoid occasional failure on setting the mark.
			-- The issue typically occurs with `dd`.
			if vim.api.nvim_win_get_buf(win) == ctx.buf then
				local cursor = vim.api.nvim_win_get_cursor(win)
				vim.api.nvim_buf_set_mark(ctx.buf, regname == "x" and "x" or op, cursor[1], cursor[2], {})
				if regname and regname:match("[a-z0-9]") then
					vim.api.nvim_buf_set_mark(ctx.buf, regname:upper(), cursor[1], cursor[2], {})
				end
			end
		end)

		-- highlight yanked region
		if vim.v.event.operator == "y" then
			vim.highlight.on_yank()
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
	group = augroup,
	once = true,
	callback = function()
		vim.filetype.add({
			extension = {
				gitcommit = "gitcommit",
				tf = "terraform",
			},
			filename = {
				[".envrc"] = "sh",
				[".profile"] = "sh",
			},
			pattern = {
				["${HOME}/%.local/share/chezmoi/.*"] = {
					function(path, bufnr)
						local filename, cnt = path:gsub("/dot_", "/.")
						if cnt == 0 then
							return
						end
						return vim.filetype.match({ filename = filename, buf = bufnr })
					end,
					{ priority = -math.huge },
				},
				["Dockerfile[._].*"] = { "dockerfile", { priority = -math.huge } },
				[".*"] = {
					function(_, bufnr)
						local shebang = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
						if not shebang or shebang:sub(1, 2) ~= "#!" then
							return
						end
						shebang = shebang:gsub("%s+", " ")

						local idx_space = shebang:find(" ")
						local path = string.sub(shebang, 3, idx_space and idx_space - 1 or nil)
						local cmd = vim.fs.basename(path)
						if cmd == "deno" then
							return "typescript"
						end
						if path == "/usr/bin/env" then
							if
								vim.startswith(shebang, "#!/usr/bin/env deno")
								or vim.startswith(shebang, "#!/usr/bin/env -S deno")
							then
								return "typescript"
							end
						end
					end,
					{ priority = -math.huge },
				},
			},
		})
	end,
})

local is_open_neovim_32660 ---@type boolean | nil

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "WinClosed", "TabEnter" }, {
	group = augroup,
	desc = "Workaround flickering <https://github.com/neovim/neovim/issues/32660>",
	callback = function(ctx)
		-- remove autocmd if the issue is closed
		local issue = "https://github.com/neovim/neovim/issues/32660"
		if is_open_neovim_32660 == nil then
			pcall(vim.system, {
				"gh",
				"issue",
				"view",
				issue,
				"--json",
				"state",
				"--jq",
				".state",
			}, { text = true }, function(obj)
				is_open_neovim_32660 = obj.stdout:gsub("\n", ""):match("^OPEN$") ~= nil
				if not is_open_neovim_32660 then
					vim.schedule(function()
						vim.notify("Updte neovim to experience TS async highlight without flickering: " .. issue)
					end)
				end
			end)
		end

		local function is_parsing(buf)
			-- try undocumented `vim.treesitter.highlighter`
			local ok, active = pcall(function()
				return vim.treesitter.highlighter.active[buf] ~= nil
			end)
			if ok then
				return active
			end

			-- otherwise, assume that the parser is active if the buffer is parsable
			local parsable = pcall(vim.treesitter.get_parser, buf)
			return parsable
		end

		local function exec()
			local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
			local bufs = {}
			for _, win in ipairs(wins) do
				local buf = vim.api.nvim_win_get_buf(win)
				if bufs[buf] == nil then
					bufs[buf] = true
				elseif bufs[buf] == true then
					if is_parsing(buf) then
						vim.g._ts_force_sync_parsing = true
						return
					end
					-- set to false to avoid multiple tests on the availability of parser
					bufs[buf] = false
				end
			end
			vim.g._ts_force_sync_parsing = false
		end

		if ctx.event == "WinClosed" then
			return vim.schedule(exec)
		end
		return exec()
	end,
})

--[[ Terminal ]]
-- nvim-remote for edit-commandline zle
if vim.fn.executable("nvr") == 1 then
	vim.env.EDITOR_CMD = [[nvr -cc "above 5split" --remote-wait-silent +"setlocal bufhidden=wipe filetype=zsh.nvr-zsh"]]
	vim.api.nvim_create_autocmd("FileType", {
		desc = "Go back to the terminal window on WinClosed. Otherwise, the current window to leftest above",
		group = augroup,
		pattern = { "zsh.nvr-zsh" },
		callback = function(args)
			vim.schedule(function()
				local parent = vim.fn.win_getid(vim.fn.winnr("#"))
				-- local local_group = vim.api.nvim_create_augroup(args.file, {})
				vim.api.nvim_create_autocmd("WinClosed", {
					-- group = local_group,
					buffer = args.buf,
					once = true,
					callback = function()
						vim.schedule(function()
							local ok = pcall(vim.api.nvim_set_current_win, parent)
							if ok then
								vim.cmd.startinsert()
							end
						end)
					end,
				})
			end)
		end,
		nested = true,
	})
end
