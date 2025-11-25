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
	{
		"https://github.com/stevearc/oil.nvim",
		config = function()
			require("oil").setup({})
		end,
	},
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
			require("ts_context_commentstring")
			require("Comment").setup({
				mappings = false,
				pre_hook = function()
					require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook()
				end,
			})
		end,
	},
	{ "https://github.com/lambdalisue/guise.vim", lazy = true }, -- denops
	{ "https://github.com/lambdalisue/askpass.vim" }, -- denops
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
			vim.keymap.set("n", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "normal")<CR>ma]])
			vim.keymap.set("n", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "normal")<CR>ma]])
			vim.keymap.set("n", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gnormal")<CR>ma]])
			vim.keymap.set("n", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gnormal")<CR>ma]])
			vim.keymap.set("v", "<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "visual")<CR>ma]])
			vim.keymap.set("v", "<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "visual")<CR>ma]])
			vim.keymap.set("v", "g<C-a>", [[<Cmd>lua require("dial.map").manipulate("increment", "gvisual")<CR>ma]])
			vim.keymap.set("v", "g<C-x>", [[<Cmd>lua require("dial.map").manipulate("decrement", "gvisual")<CR>ma]])
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
		"https://github.com/JoosepAlviste/nvim-ts-context-commentstring",
		lazy = true, -- will be loaded via Comment.nvim
		config = function()
			require("ts_context_commentstring").setup({ enable_autocmd = false })
		end,
	},
	-- 'haringsrob/nvim_context_vt',
	{
		"https://github.com/nvim-treesitter/nvim-treesitter-context",
		event = "CursorHold",
		branch = "master",
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
			require("atusy.keymap.palette").add_item("n", "toggle treesitter context", function()
				require("treesitter-context").toggle()
			end)
		end,
	},
	{
		"https://github.com/RRethy/nvim-treesitter-endwise",
		ft = { "bash", "elixir", "fish", "julia", "lua", "luau", "ruby", "verilog", "vim" },
		config = function()
			require("nvim-treesitter-endwise").init()
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

			vim.keymap.set({ "x", "o" }, "<Plug>(treemonkey)", function()
				local mode = vim.api.nvim_get_mode()
				if mode.mode == "V" or mode.mode == "noV" then
					require("treemonkey").select(vim.tbl_extend("force", base_opts, {
						filter = require("treemonkey.filters").linewise,
					}))
					return
				end
				require("treemonkey").select(base_opts)
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
		-- required by codecompanion
		"https://github.com/zbirenbaum/copilot.lua",
		cmd = "Copilot",
		config = function()
			-- disable completions
			require("copilot").setup({ suggestion = { auto_trigger = false }, filetypes = { ["*"] = false } })
		end,
	},
	{
		"https://github.com/atusy/aibou.nvim",
		dev = true,
		init = function()
			vim.keymap.set("n", "<plug>(s)n", function()
				require("aibou.codecompanion").start({
					system_prompt = require("atusy.ai.prompt.gal").GAL_PAIR_PROGRAMMING.system_prompt,
					user_prompt = "#{lsp}\n#{buffer}\n\n日本語でペアプロしよ。",
				})
			end)
		end,
	},
	{
		"https://github.com/ravitemer/mcphub.nvim",
		build = "bundled_build.lua",
		config = function()
			require("mcphub").setup({
				use_bundled_binary = true,
				extensions = {
					avante = {},
					codecompanion = {
						-- Show the mcp tool result in the chat buffer
						show_result_in_chat = true,
						-- Make chat #variables from MCP server resources
						make_vars = true,
						-- Create slash commands for prompts
						make_slash_commands = true,
					},
				},
			})
		end,
	},
	{
		"https://github.com/yetone/avante.nvim",
		cond = false,
		build = "make",
		lazy = true,
		config = function()
			require("copilot")
			require("avante").setup({
				hints = { enabled = false },
				provider = "copilot",
				system_prompt = function()
					local hub = require("mcphub").get_hub_instance()
					return hub:get_active_servers_prompt()
				end,
				-- The custom_tools type supports both a list and a function that returns a list. Using a function here prevents requiring mcphub before it's loaded
				custom_tools = function()
					return {
						require("mcphub.extensions.avante").mcp_tool(),
					}
				end,
				disabled_tools = {
					"list_files", -- Built-in file operations
					"search_files",
					"read_file",
					"create_file",
					"rename_file",
					"delete_file",
					"create_dir",
					"rename_dir",
					"delete_dir",
					"bash", -- Built-in terminal access
				},
			})
		end,
	},
	{
		"https://github.com/CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		lazy = true,
		cond = false,
		init = function(p)
			if not p.cond then
				return
			end
			-- p stands for pilot
			vim.keymap.set({ "n", "x" }, "<plug>(s)p", '<cmd>lua require("CopilotChat").open()<cr>')
		end,
		config = function(opts)
			if not opts.cond then
				return
			end
			local prompts = {}
			for _, nm in pairs({ "gal", "copilot_chat" }) do
				for k, v in pairs(require("atusy.ai.prompt." .. nm)) do
					if v.system_prompt and not v.prompt then
						prompts[k] = v
					end
				end
			end
			require("CopilotChat").setup({ prompts = prompts })
		end,
	},

	-- filetype specific
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
