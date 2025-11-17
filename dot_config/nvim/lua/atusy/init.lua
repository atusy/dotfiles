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
vim.g.clipboard = "osc52"

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
local ok_extui, extui = pcall(require, "vim._extui")
if ok_extui then
	extui.enable({ enable = true, msg = { target = "msg", timeout = 4000 } })
end

--[[ commands ]]
vim.api.nvim_create_user_command("W", "write !sudo tee % >/dev/null", {})

--[[ mappings ]]
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

-- mappings: window management
vim.keymap.set("n", "<C-W><C-V>", "<C-W><C-V><Cmd>horizontal wincmd =<CR>")
vim.keymap.set("n", "<C-W><C-S>", "<C-W><C-S><Cmd>vertical wincmd =<CR>")
for _, k in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set("n", "<C-W>" .. k, function()
		require("atusy.cmd.wincmd")[k]()
	end, { desc = "switch windows or panes of terminal multiplexers" })
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

-- mappings: undo/redo
-- they are too noisy when using extui
vim.keymap.set("n", "u", "<Cmd>silent! undo<CR>")
vim.keymap.set("n", "<c-r>", "<Cmd>silent! redo<CR>")

-- mappings: jumplist
vim.keymap.set("n", "g<C-O>", function()
	return require("atusy.misc").jump_file(false)
end, { expr = true })
vim.keymap.set("n", "g<C-I>", function()
	return require("atusy.misc").jump_file(true)
end, { expr = true })

-- mappings: save and ...
vim.keymap.set({ "n", "x" }, "<Plug>(save)", function()
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

--[[ LSP ]]
require("atusy.lsp").setup()

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
		require("atusy.filetype").add()
	end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
	group = augroup,
	callback = function(ctx)
		if
			string.find(vim.fs.basename(ctx.file) or "", ".", 2, true)
			or string.sub(vim.api.nvim_buf_get_lines(ctx.buf, 0, 1, false)[1] or "", 1, 2) ~= "#!"
		then
			return
		end
		local path = vim.api.nvim_buf_get_name(ctx.buf)
		vim.system({ "chmod", "+x", path }, { detach = true }, function() end)
	end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinNew", "WinClosed", "TabEnter" }, {
	group = augroup,
	desc = "Workaround flickering <https://github.com/neovim/neovim/issues/32660>",
	callback = function(ctx)
		require("atusy.treesitter").workaround_flickering(ctx)
	end,
})

--[[ Terminal ]]
-- nvim-remote for edit-commandline zle
if vim.fn.executable("nvr") == 1 then
	vim.env.EDITOR_ZSH = [[nvr -cc "above 5split" --remote-wait-silent +"setlocal bufhidden=wipe filetype=zsh.nvr-zsh"]]
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
