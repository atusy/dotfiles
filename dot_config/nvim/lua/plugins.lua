--[[
TODO:

- https://github.com/edluffy/hologram.nvim
  - might be interesting to view images from within Neovim

- https://github.com/nullchilly/fsread.nvim
  - wanna apply only to @string, @comment, or something like that
--  ]]

vim.api.nvim_create_autocmd("User", {
	pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean" },
	callback = function()
		vim.system({ "chezmoi", "add", require("lazy.core.config").options.lockfile })
		require("plugins.denops.utils").cache_plugin()
	end,
})

return {
	-- basic dependencies
	{ "https://github.com/nvim-lua/plenary.nvim", lazy = true },
	{
		"https://github.com/delphinus/cellwidths.nvim",
		event = { "BufReadPost", "ModeChanged" },
		config = function()
			-- ga
			-- https://en.wikipedia.org/wiki/List_of_Unicode_characters
			require("cellwidths").setup({ name = "default" })
			vim.cmd.CellWidthsAdd("{ 0xe000, 0xf8ff, 2 }") -- 私用領域（外字領域）
			vim.cmd.CellWidthsAdd("{ 0x2423, 0x2423, 2 }") -- ␣
			vim.cmd.CellWidthsAdd("{ 0xf0219, 0xf07d4, 2 }") -- 󰈙 to 󰟔
			vim.cmd.CellWidthsDelete("{" .. table.concat({
				0x2190,
				0x2191,
				0x2192,
				0x2193, -- ←↑↓→
				0x25b2,
				0x25bc, -- ▼▲
				0x25cf, -- ●
				0x2713, -- ✓
				0x279c, -- ➜
				0x2717, -- ✗
				0xe727, --  actually 2?
			}, ", ") .. "}")
		end,
	},
	{ "https://github.com/MunifTanjim/nui.nvim", lazy = true },

	-- utils
	{
		"https://github.com/numToStr/Comment.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("n", "gcc", [[<Cmd>lua require("Comment.api").toggle.linewise.current()<CR>]])
			vim.keymap.set("x", "gc", [[<Esc><Cmd>lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>]])
			vim.keymap.set(
				"x",
				"gb",
				[[<Esc><Cmd>lua require("Comment.api").toggle.blockwise(vim.fn.visualmode())<CR>]]
			)
		end,
		config = function()
			require("Comment").setup({
				mappings = false,
				pre_hook = function(ctx)
					-- try find commentstring via kakehashi
					local blockwise = ctx.ctype == require("Comment.utils").ctype.blockwise
					local ok, commentstring = pcall(function()
						local bufnr = vim.api.nvim_get_current_buf()
						-- consult the commented rows, excluding indentation and trailing
						-- blanks, so the range stays inside the capture holding the code
						local first = vim.api.nvim_buf_get_lines(bufnr, ctx.range.srow - 1, ctx.range.srow, false)[1]
							or ""
						local last = ctx.range.srow == ctx.range.erow and first
							or vim.api.nvim_buf_get_lines(bufnr, ctx.range.erow - 1, ctx.range.erow, false)[1]
							or ""
						return require("kakehashi.extra.commentstring").get({
							bufnr = bufnr,
							range = {
								start = { line = ctx.range.srow - 1, character = (first:find("%S") or 1) - 1 },
								["end"] = {
									line = ctx.range.erow - 1,
									character = vim.str_utfindex(last, "utf-16", #(last:gsub("%s+$", "")), false),
								},
							},
						})
					end)
					-- blockwise needs a closing side ("{/* %s */}" has one, "-- %s" not)
					if ok and commentstring and (not blockwise or commentstring:find("%%s%s*%S")) then
						return commentstring
					end
					-- fall back to Comment.nvim's filetype table / the option here
					-- in the hook: ft.get is a plain table lookup, no treesitter
					return require("Comment.ft").get(vim.bo.filetype, ctx.ctype)
						or (not blockwise and vim.bo.commentstring)
						or error(vim.bo.filetype .. " doesn't support block comments!")
				end,
			})
		end,
	},
	{ "https://github.com/segeljakt/vim-silicon", cmd = { "Silicon", "SiliconHighlight" } }, -- pacman -S silicon
	{ "https://github.com/tpope/vim-characterize", cmd = { "Characterize" } },
	{ "https://github.com/thinca/vim-partedit", cmd = "Partedit" },

	-- ui
	{ "https://github.com/xiyaowong/nvim-transparent", lazy = true }, -- watch, but prefer atusy.highlight to support styler.nvim

	-- windows and buffers
	{
		"https://github.com/m00qek/baleia.nvim",
		lazy = true,
		config = function()
			require("atusy.keymap.palette").add_item("n", "parse ANSI escape sequences", function()
				require("baleia").setup().once(vim.api.nvim_get_current_buf())
			end)
		end,
	},
	{
		"https://github.com/tyru/capture.vim",
		cmd = "Capture",
		init = function()
			vim.keymap.set("c", "<C-X><C-C>", function()
				local t = vim.fn.getcmdtype()
				if t ~= ":" then
					return
				end
				local l = vim.fn.getcmdline()
				vim.schedule(function()
					vim.cmd("Capture " .. l)
				end)
				return "<C-C>"
			end, { expr = true })
		end,
	},

	-- better something
	{
		"https://github.com/chrisbra/Recover.vim",
		event = "SwapExists", -- NOTE: testing
		-- lazy = false,
	},
	{
		"https://github.com/lambdalisue/kensaku.vim", -- denops
		lazy = false,
		config = function(p)
			if p.lazy then
				require("denops-lazy").load("kensaku.vim")
			end
		end,
	},
	{
		"https://github.com/wsdjeg/vim-fetch", -- :e with linenumber
		lazy = false, -- some how event-based lazy loading won't work as expected
	},
	{
		"https://github.com/andymass/vim-matchup",
		event = "BufReadPost",
		config = function()
			vim.g.matchup_matchparen_offscreen = { method = "status_manual" }
			vim.g.matchup_treesitter_enable_quotes = true
			vim.g.matchup_treesitter_disable_virtual_text = true
			vim.g.matchup_treesitter_include_match_words = true
		end,
	},
	{
		"https://github.com/monaqa/dial.nvim",
		lazy = true,
		init = function()
			-- also set `a`-mark
			vim.keymap.set("n", "<C-A>", [[<Cmd>lua require("dial.map").manipulate("increment", "normal")<CR>ma]])
			vim.keymap.set("n", "<C-X>", [[<Cmd>lua require("dial.map").manipulate("decrement", "normal")<CR>ma]])
			vim.keymap.set("n", "g<C-A>", [[<Cmd>lua require("dial.map").manipulate("increment", "gnormal")<CR>ma]])
			vim.keymap.set("n", "g<C-X>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gnormal")<CR>ma]])
			vim.keymap.set("v", "<C-A>", [[<Cmd>lua require("dial.map").manipulate("increment", "visual")<CR>ma]])
			vim.keymap.set("v", "<C-X>", [[<Cmd>lua require("dial.map").manipulate("decrement", "visual")<CR>ma]])
			vim.keymap.set("v", "g<C-A>", [[<Cmd>lua require("dial.map").manipulate("increment", "gvisual")<CR>ma]])
			vim.keymap.set("v", "g<C-X>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gvisual")<CR>ma]])
		end,
	},

	-- motion
	{
		"https://github.com/atusy/budoux.lua",
		dev = true,
		lazy = true,
	},
	{
		"https://github.com/atusy/budouxify.nvim",
		dev = true,
		lazy = true,
		init = function()
			vim.keymap.set("n", "W", function()
				local pos = require("budouxify.motion").find_forward({
					head = true,
				})
				if pos then
					vim.api.nvim_win_set_cursor(0, { pos.row, pos.col })
				end
			end)
			vim.keymap.set("n", "E", function()
				local pos = require("budouxify.motion").find_forward({
					head = false,
				})
				if pos then
					vim.api.nvim_win_set_cursor(0, { pos.row, pos.col })
				end
			end)
		end,
	},
	{
		"https://github.com/atusy/jab.nvim",
		lazy = true,
		init = function()
			for _, key in ipairs({ "f", "F", "t", "T" }) do
				vim.keymap.set({ "n", "x", "o" }, key, function()
					if vim.v.count > 0 then
						-- Prefer builtin behavior when count is given
						return key
					end
					return require("jab")[key]()
				end, { expr = true })
			end
			vim.keymap.set({ "n", "x", "o" }, "<Plug>(jab-incremental)", function()
				return require("jab").jab_win()
			end, { expr = true })
			vim.keymap.set("n", ";", "m'<Plug>(jab-incremental)")
			vim.keymap.set({ "x", "o" }, ";", "<Plug>(jab-incremental)")
		end,
	},
	{
		"https://github.com/haya14busa/vim-edgemotion",
		keys = {
			{ "<A-j>", "<Plug>(edgemotion-j)", mode = "" },
			{ "<A-k>", "<Plug>(edgemotion-k)", mode = "" },
		},
	},
	{
		"https://github.com/rapan931/lasterisk.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("n", "*", [[<Cmd>lua require("lasterisk").search()<CR>]])
			vim.keymap.set("n", "g*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR>]])
			vim.keymap.set("x", "*", [[<Cmd>lua require("lasterisk").search({ is_whole = false })<CR><C-\><C-N>]])
		end,
	},

	-- treesitter
	{
		"https://github.com/atusy/treemonkey.nvim",
		lazy = true,
		dev = true,
		init = function()
			local base_opts = {
				action = require("treemonkey.actions").unite_selection,
				highlight = { backdrop = "Comment" },
				ignore_injections = false,
				experimental = { treesitter_context = true },
			}

			vim.keymap.set({ "x", "o" }, "<Plug>(treemonkey)", function()
				local mode = vim.api.nvim_get_mode()
				if mode.mode == "V" or mode.mode == "noV" then
					require("treemonkey.lsp.selection_range").select(vim.tbl_extend("force", base_opts, {
						filter = require("treemonkey.filters").linewise,
					}))
					return
				end
				require("treemonkey.lsp.selection_range").select(base_opts)
			end)
			vim.keymap.set({ "x", "o" }, "m", "<Plug>(treemonkey)")
			vim.keymap.set("n", "zf", "zfV<Plug>(treemonkey)")
		end,
	},
	{
		"https://github.com/atusy/tsnode-marker.nvim",
		lazy = true,
		init = function()
			local group = vim.api.nvim_create_augroup("atusy.tsnode-maker", {})
			vim.api.nvim_create_autocmd("FileType", {
				desc = "High-level reproduction of highlights by delta via GinDiff",
				group = group,
				pattern = "gin-diff",
				callback = function(ctx)
					local nm = vim.api.nvim_buf_get_name(ctx.buf)
					if not nm:match("processor=delta") then
						return
					end
					vim.api.nvim_set_hl(0, "DeltaLineAdded", { fg = "#FFFFFF", bg = "#002800" })
					vim.api.nvim_set_hl(0, "DeltaLineDeleted", { fg = "#FFFFFF", bg = "#3f0001" })
					require("tsnode-marker").set_automark(ctx.buf, {
						target = { "line_deleted", "line_added" },
						hl_group = function(_, node)
							local t = node:type()
							return ({
								line_added = "DeltaLineAdded",
								line_deleted = "DeltaLineDeleted",
							})[t] or "None"
						end,
						priority = 101, -- to override treesitter highlighting
					})
				end,
			})
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = "markdown",
				callback = function(ctx)
					-- blank target requires capture group @tsnodemarker
					-- dot_config/nvim/after/queries/markdown/highlights.scm
					require("tsnode-marker").set_automark(ctx.buf, {
						-- target = { "code_fence_content" },
						hl_group = "@illuminate",
					})
				end,
			})
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = { "python", "go" },
				callback = function(ctx)
					local function is_def(n)
						return vim.tbl_contains({
							"func_literal",
							"function_declaration",
							"function_definition",
							"method_declaration",
							"method_definition",
						}, n:type())
					end
					require("tsnode-marker").set_automark(ctx.buf, {
						target = function(_, node)
							if not is_def(node) then
								return false
							end
							local parent = node:parent()
							while parent do
								if is_def(parent) then
									return true
								end
								parent = parent:parent()
							end
							return false
						end,
						hl_group = "@illuminate",
					})
				end,
			})
		end,
		config = function()
			-- vim.api.nvim_set_hl(0, "@tsnodemarker", { link = "@illuminate" })
		end,
	},

	-- terminal
	{
		"https://github.com/chomosuke/term-edit.nvim",
		event = "TermEnter",
		config = function()
			require("term-edit").setup({
				prompt_end = "[»#$] ",
				mapping = { n = { s = false, S = false } },
			})
		end,
	},
	{
		"https://github.com/akinsho/toggleterm.nvim",
		lazy = true,
		init = function()
			vim.keymap.set({ "n", "t" }, "<C-T>", function()
				require("toggleterm") -- just to lazy load
				local open, wins = require("toggleterm.ui").find_open_windows()
				if open then
					local curtab = vim.api.nvim_get_current_tabpage()
					if not vim.tbl_contains(vim.api.nvim_tabpage_list_wins(curtab), wins[1].window) then
						require("toggleterm.ui").close_and_save_terminal_view(wins)
						vim.api.nvim_set_current_tabpage(curtab)
					end
				end
				vim.cmd(vim.v.count .. "ToggleTerm")
			end, { desc = "Allow reopen toggleterm in different tabpage" })
			vim.keymap.set(
				"n",
				" <CR>",
				"<Cmd>lua require('toggleterm')<CR>:ToggleTermSendCurrentLine<CR>",
				{ silent = true }
			)
			vim.keymap.set(
				"v",
				" <CR>",
				"<Cmd>lua require('toggleterm')<CR>:ToggleTermSendVisualSelection<CR>",
				{ silent = true }
			)
		end,
		config = function()
			require("toggleterm").setup({
				open_mapping = false,
				insert_mappings = false,
				shade_terminals = false,
				shading_factor = 0,
			})
		end,
	},

	-- filetype specific
	{ "https://github.com/itchyny/vim-qfedit", ft = "qf" },
	{ "https://github.com/thinca/vim-qfreplace", ft = "qf" },
}
