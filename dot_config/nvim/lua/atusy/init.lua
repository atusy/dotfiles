-- [[ helpers ]]
local set_keymap = vim.keymap.set
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

--[[ commands ]]
vim.api.nvim_create_user_command("W", "write !sudo tee % >/dev/null", {})

--[[ mappings ]]
vim.g.mapleader = " "
set_keymap({ "n", "x" }, "s", "<Nop>") -- be prefix for sandwich and fuzzy finders
set_keymap("n", "<C-G>", "<Cmd>lua if vim.o.laststatus == 0 then vim.cmd.f() end<CR><Plug>(C-G)")
set_keymap("n", "<Plug>(C-G)<C-G>", '<Cmd>let @+ = expand("%:~:.")<CR>')
set_keymap("n", "<Plug>(C-G)g", '<Cmd>let @+ = expand("%:~")<CR>')
set_keymap("n", "H", "H<Plug>(H)")
set_keymap("n", "<Plug>(H)H", "<PageUp>H<Plug>(H)")
set_keymap("n", "L", "L<Plug>(L)")
set_keymap("n", "<Plug>(L)L", "<PageDown>Lzb<Plug>(L)")
set_keymap("x", "<C-G>", "<Plug>(C-G)")
set_keymap("x", "<Plug>(C-G)<C-G>", "<C-G>")
set_keymap("c", "<C-A>", "<Home>")
set_keymap("t", "<C-W>", [[<C-\><C-N><C-W>]])
set_keymap({ "", "!", "t" }, [[<C-\>]], [[<C-\><C-N>]], { nowait = true })
set_keymap("x", "p", "P")
set_keymap("x", "P", "p")
set_keymap("x", "zf", [[mode() ==# 'V' ? 'zf' : 'Vzf']], { expr = true })
set_keymap("x", " ue", [[<Cmd>lua require("atusy.misc").urlencode()<CR>]])
set_keymap("x", " ud", [[<Cmd>lua require("atusy.misc").urldecode()<CR>]])
set_keymap({ "n", "x" }, "gf", [[<Cmd>lua require("atusy.misc").open_cfile()<CR>]])
set_keymap({ "n", "x" }, "<C-W><C-F>", [[<Cmd>lua require("atusy.misc").open_cfile({ cmd = "vs" })<CR>]])

-- mappings: window management
set_keymap("n", "<C-W><C-V>", "<C-W><C-V><Cmd>horizontal wincmd =<CR>")
set_keymap("n", "<C-W><C-S>", "<C-W><C-S><Cmd>vertical wincmd =<CR>")
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
set_keymap("n", "gt", "gt<Plug>(gt)")
set_keymap("n", "gT", "gT<Plug>(gt)")
set_keymap("n", "<Plug>(gt)t", "gt<Plug>(gt)")
set_keymap("n", "<Plug>(gt)T", "gT<Plug>(gt)")

-- mappings: diagnostics
set_keymap("n", "<Leader>e", [[<Cmd>lua vim.diagnostic.open_float()<CR>]])

-- mappings: insert-mode horizontal moves in the current undo block
set_keymap("i", "<Left>", "<C-G>U<Left>")
set_keymap("i", "<Right>", "<C-G>U<Right>")

-- mappings: register
set_keymap({ "n", "x" }, "-", '"_')
set_keymap({ "n", "x" }, "x", '"_x')
set_keymap({ "n", "x" }, "X", '"_X')
set_keymap({ "n", "x" }, "gy", '"+y')
set_keymap({ "n", "x" }, "gY", '"+Y')

-- mappings: textobj
-- set_keymap({ "o", "x" }, "ii", "2i") -- ii' selects 'foo' without outer spaces (:h v_i)
set_keymap({ "o", "x" }, "ii", ":<c-u>keepjumps normal! g_v^<cr>", { silent = true })
set_keymap({ "o", "x" }, "ae", ":<c-u>keepjumps normal! G$vgo<cr>", { silent = true })

-- mappings: mouse
set_keymap("!", "<LeftMouse>", "<Esc><LeftMouse>")
set_keymap("n", "<2-LeftMouse>", "gf", { remap = true })
set_keymap("n", "<LeftDrag>", "<Nop>")
set_keymap("n", "<LeftRelease>", "<Nop>")

-- mappings: jumplist
set_keymap("n", "g<C-O>", function()
	return require("atusy.misc").jump_file(false)
end, { expr = true })
set_keymap("n", "g<C-I>", function()
	return require("atusy.misc").jump_file(true)
end, { expr = true })

-- mappings: save and ...
set_keymap({ "n", "x" }, "<Plug>(save)", function()
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
set_keymap({ "i", "n" }, "<C-S>", [[<C-\><C-N><Plug>(save)<Plug>(C-S)]], { desc = "save" })
set_keymap("n", "<Plug>(C-S)<C-A>", "<cmd>wa<cr>", { desc = "save all" })
set_keymap("n", "<Plug>(C-S)<C-Q>", "<cmd>q<cr>", { desc = "save and quit" })
set_keymap("n", "<Plug>(C-S)<C-M>", function()
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

set_keymap({ "", "t" }, "<S-Up>", function()
	win_move_or_cmd(-1, 0, "2+")
end)
set_keymap({ "", "t" }, "<S-Down>", function()
	win_move_or_cmd(1, 0, "2-")
end)
set_keymap({ "", "t" }, "<S-Right>", function()
	win_move_or_cmd(0, 2, "2>")
end)
set_keymap({ "", "t" }, "<S-Left>", function()
	win_move_or_cmd(0, -2, "2<")
end)

-- mappings: macro
-- disable macro a-z except q on normal mode and entirely on visual mode
set_keymap("x", "q", "<Nop>")
set_keymap("n", "q", function()
	return vim.fn.reg_recording() == "" and "<Plug>(q)" or "q"
end, { expr = true })
set_keymap("n", "<Plug>(q)q", "qq")
set_keymap("n", "<Plug>(q):", "q:")
set_keymap("n", "<Plug>(q)/", "q/")
set_keymap("n", "<Plug>(q)?", "q?")

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
	callback = function()
		-- copy unnamed regsiter to contextful register
		-- i.e., change to c, delete to d, and yank to y
		-- note that `x` is treated as delete, not x.
		-- I map `x` and `X` register to blackhole.
		if vim.v.event.regname == "" then
			vim.fn.setreg(vim.v.event.operator, vim.fn.getreg())
		end

		-- highlight yanked region
		if vim.v.event.operator == "y" then
			vim.highlight.on_yank()
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
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
			},
		})
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
