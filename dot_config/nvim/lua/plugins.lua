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
		pcall(vim.fn["ddc#set_static_import_path"])
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
	{ "https://github.com/nvim-tree/nvim-web-devicons", lazy = true },
	{ "https://github.com/stevearc/dressing.nvim", lazy = true },
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
			require("ts_context_commentstring")
			require("Comment").setup({
				mappings = false,
				pre_hook = function()
					require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
				end,
			})
		end,
	},
	{ "https://github.com/lambdalisue/guise.vim" }, -- denops
	{ "https://github.com/lambdalisue/askpass.vim" }, -- denops
	{ "https://github.com/segeljakt/vim-silicon", cmd = { "Silicon", "SiliconHighlight" } }, -- pacman -S silicon
	{ "https://github.com/tpope/vim-characterize", keys = { "ga" } },
	{ "https://github.com/thinca/vim-partedit", cmd = "Partedit" },

	-- ui
	{
		"https://github.com/lukas-reineke/indent-blankline.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("n", "<Bar>", function()
				-- without count, toggle indent_blankline. Otherwise fallback to native <Bar>-like behavior
				if vim.v.count == 0 then
					-- must be scheduled to suppress textlock related errors
					require("ibl").update({ enabled = not require("ibl.config").get_config(-1).enabled })
				else
					vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], vim.v.count - 1 })
				end
			end)
		end,
		config = function()
			local viridis = math.random() > 0.5
			local function set_hl()
				if viridis then
					-- viridis
					vim.api.nvim_set_hl(0, "IBLIndent1", { fg = "#440154", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent2", { fg = "#3b528b", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent3", { fg = "#21918c", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent4", { fg = "#5ec962", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent5", { fg = "#fde725", nocombine = true })
				else
					-- cividis
					vim.api.nvim_set_hl(0, "IBLIndent1", { fg = "#50586c", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent2", { fg = "#757575", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent3", { fg = "#9b9377", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent4", { fg = "#afa473", nocombine = true })
					vim.api.nvim_set_hl(0, "IBLIndent5", { fg = "#dbc760", nocombine = true })
				end
			end
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("atusy.ibl", {}),
				callback = set_hl,
			})
			set_hl()
			require("ibl").setup({
				enabled = false,
				indent = { highlight = { "IBLIndent1", "IBLIndent2", "IBLIndent3", "IBLIndent4", "IBLIndent5" } },
				scope = { enabled = false },
			})
		end,
	},
	{ "https://github.com/xiyaowong/nvim-transparent", lazy = true }, -- watch, but prefer atusy.highlight to support styler.nvim

	-- windows and buffers
	{
		"https://github.com/echasnovski/mini.bufremove",
		lazy = true,
		config = function()
			require("atusy.keymap.palette").add_item(
				"n",
				"Bdelete",
				[[<Cmd>lua require("mini.bufremove").delete()<CR>]]
			)
			require("atusy.keymap.palette").add_item(
				"n",
				"Bwipeout",
				[[<Cmd>lua require("mini.bufremove").wipeout()<CR>]]
			)
		end,
	},
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
			vim.keymap.set("c", "<c-x><c-c>", function()
				local t = vim.fn.getcmdtype()
				if t ~= ":" then
					return
				end
				local l = vim.fn.getcmdline()
				vim.schedule(function()
					vim.cmd("Capture " .. l)
				end)
				return "<c-c>"
			end, { expr = true })
		end,
	},
	{ "https://github.com/thinca/vim-qfreplace", cmd = "Qfreplace" },

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
			-- disable treesitter integration as it becomes very slow somehow...
			require("nvim-treesitter.configs").setup({
				matchup = {
					enable = true,
					disable_virtual_text = true,
					include_match_words = true,
					enable_quotes = true,
				},
			})
		end,
	},
	{
		"https://github.com/Wansmer/treesj",
		lazy = true,
		config = function()
			require("treesj").setup({ use_default_keymaps = false })
			-- treesj does not support visual mode, so leave the mode and use cursor as the node indicator
			require("atusy.keymap.palette").add_item(
				"",
				"join lines based on AST",
				[[<C-\><C-N>:lua require('treesj').join()<CR>]]
			)
			require("atusy.keymap.palette").add_item(
				"",
				"split lines based on AST",
				[[<C-\><C-N>:lua require('treesj').split()<CR>]]
			)
		end,
	},
	{
		"https://github.com/monaqa/dial.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("n", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "normal")<CR>]])
			vim.keymap.set("n", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "normal")<CR>]])
			vim.keymap.set("n", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gnormal")<CR>]])
			vim.keymap.set("n", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gnormal")<CR>]])
			vim.keymap.set("v", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "visual")<CR>]])
			vim.keymap.set("v", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "visual")<CR>]])
			vim.keymap.set("v", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gvisual")<CR>]])
			vim.keymap.set("v", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gvisual")<CR>]])
		end,
	},

	-- statusline
	{
		"https://github.com/nvim-lualine/lualine.nvim",
		lazy = true,
		init = function()
			-- want statusline on creating non-relative windows
			vim.opt.laststatus = 0
			vim.api.nvim_create_autocmd("WinNew", {
				group = vim.api.nvim_create_augroup("atusy.lualine", {}),
				callback = function(ctx)
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
					require("nvim-web-devicons")
					require("lualine").setup({
						options = { theme = "moonfly", component_separators = "" },
						sections = {
							lualine_a = {
								{
									"mode",
									fmt = function(x)
										return x == "TERMINAL" and x or ""
									end,
								},
							},
							lualine_b = { { "filetype", icon_only = true }, { "filename", path = 1 } },
							lualine_c = {},
							lualine_x = {},
							lualine_y = { { "location" } },
							lualine_z = {},
						},
						inactive_sections = {
							lualine_a = {},
							lualine_b = { { "filetype", icon_only = true }, { "filename", path = 1 } },
							lualine_c = {},
							lualine_x = {},
							lualine_y = { { "location" } },
							lualine_z = {},
						},
						extensions = {},
					})
					vim.api.nvim_del_autocmd(ctx.id)
				end,
			})
		end,
	},

	-- motion
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
		"https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
		lazy = true, -- will be loaded via Comment.nvim
		config = function()
			require("ts_context_commentstring").setup({ enable_autocmd = false })
		end,
	},
	{
		"https://github.com/nvim-treesitter/nvim-treesitter",
		build = function()
			-- force (re-)install some parsers bundled with Neovim
			vim.cmd.TSUpdate()
		end,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- install directory of treesitter parsers
			local treesitterpath = vim.fn.stdpath("data") .. "/treesitter"
			vim.opt.runtimepath:prepend(treesitterpath)

			-- add non-official parsers
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			local parser_uri = vim.uv.os_homedir() .. "/ghq/github.com/atusy/tree-sitter-uri" ---@diagnostic disable-line: undefined-field
			if not vim.uv.fs_stat(parser_uri) then ---@diagnostic disable-line: undefined-field
				parser_uri = "https://github.com/atusy/tree-sitter-uri"
			end
			parser_config.uri = {
				install_info = {
					url = parser_uri,
					branch = "main",
					files = { "src/parser.c" },
					generate_requires_npm = false, -- if stand-alone parser without npm dependencies
					requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
				},
				filetype = "uri", -- if filetype does not match the parser name
			}
			parser_config.unifieddiff = {
				install_info = {
					url = "https://github.com/monaqa/tree-sitter-unifieddiff",
					branch = "main",
					files = { "src/parser.c", "src/scanner.c" },
				},
				filetype = "diff", -- if filetype does not agrees with parser name
			}

			-- setup
			require("nvim-treesitter.configs").setup({
				parser_install_dir = treesitterpath,
				ensure_installed = "all",
				highlight = {
					enable = true,
					disable = function(lang)
						local ok = pcall(vim.treesitter.query.get, lang, "highlights")
						return not ok
					end,
					additional_vim_regex_highlighting = false,
				},
				indent = { enable = true },
				incremental_selection = { enable = false },
			})

			-- register parsers to some other languages
			vim.treesitter.language.register("bash", "zsh")
			vim.treesitter.language.register("bash", "sh")
			vim.treesitter.language.register("json", "jsonl")
			vim.treesitter.language.register("json", "ndjson")
			vim.treesitter.language.register("hcl", "tf")
			vim.treesitter.language.register("unifieddiff", "gin-diff")

			-- custom highlights
			local function hi()
				vim.api.nvim_set_hl(0, "@illuminate", { bg = "#383D47" })
			end

			hi()
			vim.api.nvim_create_autocmd(
				"ColorScheme",
				{ group = vim.api.nvim_create_augroup("atusy.nvim-treesitter", {}), callback = hi }
			)

			-- command palette
			require("atusy.keymap.palette").add_item(
				"n",
				"treesitter: force install some queries",
				[[<Cmd>TSInstall! lua query vimdoc vim c python bash markdown markdown_inline<CR>]]
			)
		end,
	},
	-- 'nvim-treesitter/playground', -- vim.treesitter.show_tree would be enough
	{
		"https://github.com/nvim-treesitter/nvim-treesitter-refactor",
		lazy = true,
		init = function()
			vim.keymap.set(
				"n",
				" r",
				[[<Cmd>lua require("nvim-treesitter-refactor.smart_rename").smart_rename(vim.fn.bufnr())<CR>]],
				{}
			)
		end,
	},
	-- 'haringsrob/nvim_context_vt',
	{
		"https://github.com/nvim-treesitter/nvim-treesitter-context",
		event = "CursorHold",
		config = function()
			require("treesitter-context").setup({
				enable = true,
				patterns = {
					css = { "media_statement", "rule_set" },
					scss = { "media_statement", "rule_set" },
					rmd = { "section" },
					yaml = { "block_mapping_pair", "block_sequence_item" },
				},
			})
		end,
	},
	{
		-- "https://github.com/RRethy/nvim-treesitter-endwise",
		"https://github.com/metiulekm/nvim-treesitter-endwise",
		commit = "ad5ab41122a0b84f27101f1b5e6e55a681f84b2f",
		ft = { "ruby", "lua", "sh", "bash", "zsh", "vim" },
		config = function()
			require("nvim-treesitter.configs").setup({ endwise = { enable = true } })
		end,
	},
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
			vim.keymap.set({ "x", "o" }, "m", function()
				require("treemonkey").select(base_opts)
			end)

			vim.keymap.set("n", "zf", "zfV<Plug>(treemonkey-multiline)")
			vim.keymap.set("o", "<Plug>(treemonkey-multiline)", function()
				require("treemonkey").select(vim.tbl_extend("force", base_opts, {
					filter = function(nodes)
						local res = {}
						for _, n in pairs(nodes) do
							local srow, _, erow, ecol = n:range()
							if erow > (srow + (ecol == 0 and 1 or 0)) then
								table.insert(res, n)
							end
						end
						return res
					end,
				}))
			end)
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

	-- autopairs
	{
		"https://github.com/hrsh7th/nvim-insx",
		event = "InsertEnter",
		config = function()
			require("insx.preset.standard").setup()
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

	-- cmdwin
	{
		"https://github.com/notomo/cmdbuf.nvim",
		lazy = true,
		init = function()
			vim.keymap.set("c", "<C-F>", function()
				require("cmdbuf").split_open(
					vim.o.cmdwinheight,
					{ line = vim.fn.getcmdline(), column = vim.fn.getcmdpos() }
				)
				vim.api.nvim_feedkeys(vim.keycode("<C-C>"), "n", true)
			end)
		end,
		config = function()
			vim.api.nvim_create_autocmd({ "User" }, {
				group = vim.api.nvim_create_augroup("atusy.cmdbuf", {}),
				pattern = { "CmdbufNew" },
				callback = function(args)
					vim.bo.bufhidden = "wipe"
					local max_count = 10
					local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
					vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, vim.list_slice(lines, #lines - max_count))
				end,
			})
		end,
	},

	-- AI
	{
		"https://github.com/github/copilot.vim",
		cond = false,
		init = function(p)
			if not p.cond then
				return
			end
			vim.g.copilot_no_tab_map = true
		end,
		config = function()
			vim.keymap.set("i", "<C-X>a", function()
				vim.notify(vim.inspect(vim.fn["copilot#GetDisplayedSuggestion"]()))
			end)
			vim.keymap.set("i", "<C-N>", "<Plug>(copilot-next)")
			vim.keymap.set("i", "<C-P>", "<Plug>(copilot-previous)")
			vim.keymap.set("i", "<C-X>l", "<Plug>(copilot-accept-line)")
			vim.keymap.set("i", "<C-X>w", "<Plug>(copilot-accept-word)")
			vim.keymap.set("i", "<C-A>", function()
				local s = vim.fn["copilot#GetDisplayedSuggestion"]()
				if s.deleteSize == 0 and s.text == "" and s.outdentSize == 0 then
					return vim.keycode("<Plug>(copilot-suggest)")
				end
				return vim.fn["copilot#Accept"]("\\<CR>")
			end, {
				expr = true,
				replace_keycodes = false,
			})
		end,
	},
	{
		"https://github.com/zbirenbaum/copilot.lua",
		-- cond = false,
		cmd = "Copilot",
		event = { "InsertEnter", "CursorHold" },
		config = function()
			require("copilot").setup({
				suggestion = {
					auto_trigger = true,
					keymap = {
						accept = false,
						accept_line = "<C-X>l",
						accept_word = "<C-X>w",
						next = "<C-N>",
						prev = "<C-P>",
					},
				},
				filetypes = { ["*"] = true },
			})
			vim.keymap.set("i", "<c-a>", function()
				if require("copilot.suggestion").is_visible() then
					require("copilot.suggestion").accept()
				else
					require("copilot.suggestion").next()
				end
			end)
		end,
	},
	{
		"https://github.com/olimorris/codecompanion.nvim",
		lazy = true,
		event = "CmdlineEnter",
		init = function()
			vim.keymap.set({ "n", "x" }, "sc", ":CodeCompanionChat ")
			vim.keymap.set({ "n", "x" }, "si", ":CodeCompanion ")
		end,
		config = function()
			require("codecompanion").setup({
				strategies = {
					chat = {
						adapter = "copilot",
					},
					inline = {
						adapter = "copilot",
					},
					agent = {
						adapter = "copilot",
					},
				},
				display = {
					action_palette = {
						provider = "telescope",
					},
				},
			})
		end,
	},
	{
		"https://github.com/yetone/avante.nvim",
		build = "make",
		config = function()
			require("avante").setup({
				provider = "copilot",
				behaviour = {
					auto_suggestions = false,
					-- auto_set_keymaps = false,
				},
			})
		end,
	},
	{
		-- support for image pasting in avante
		"https://github.com/HakonHarnes/img-clip.nvim",
		event = "VeryLazy",
		opts = {
			default = {
				embed_image_as_base64 = false,
				prompt_for_file_name = false,
				drag_and_drop = { insert_mode = true },
				use_absolute_path = true, -- for windows
			},
		},
	},

	-- filetype specific
	{
		"https://github.com/MeanderingProgrammer/render-markdown.nvim",
		opts = { file_types = { "markdown", "Avante" } },
		ft = {
			-- "markdown", -- too noisy
			"Avante",
		},
	},
	{
		"https://github.com/barrett-ruth/import-cost.nvim",
		ft = { "javascript", "typescript", "typescriptreact" },
		build = "sh install.sh bun",
		config = function()
			require("import-cost").setup()
		end,
	},
	{
		"https://github.com/phelipetls/jsonpath.nvim",
		lazy = true,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("atusy.jsonpath", {}),
				pattern = "json",
				callback = function(ctx)
					require("atusy.keymap.palette").add_item("n", "clipboard: json path", function()
						local path = require("jsonpath").get()
						vim.fn.setreg("+", path)
						vim.notify("jsonpath: " .. path)
					end, { buffer = ctx.buf })
				end,
			})
		end,
	},
	{ "https://github.com/itchyny/vim-qfedit", ft = "qf" },
	{
		"https://github.com/kevinhwang91/nvim-bqf",
		ft = "qf",
	},
	{ "https://github.com/jmbuhr/otter.nvim", lazy = true },
	{
		"https://github.com/quarto-dev/quarto-nvim",
		ft = { "quarto" },
		config = function()
			require("quarto").setup({})
		end,
	},
}
