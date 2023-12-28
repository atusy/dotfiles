return {
	{
		"https://github.com/folke/flash.nvim",
		lazy = true,
		init = function(p)
			--[[ f-motion ]]
			local motions = {
				f = { label = { after = false, before = { 0, 0 } }, jump = { inclusive = true, autojump = true } },
				t = {
					label = { after = false, before = { 0, 1 } },
					jump = { inclusive = true, autojump = true, pos = "start" },
				},
				F = {
					label = { after = false, before = { 0, 0 } },
					search = { forward = false },
					jump = { autojump = true, pos = "start", inclusive = false },
				},
				T = {
					label = { after = false, before = { 0, 0 } },
					search = { forward = false },
					jump = { autojump = true, pos = "end", inclusive = false },
				},
			}

			-- HACK: allow dot-repeat to automatically select label
			local label_on_repeat
			local function provide_hacks()
				-- overwride flash.util.get_char
				local util = require("flash.util")
				local get_char = util.get_char
				if require("flash.repeat").is_repeat then
					util.get_char = function()
						util.get_char = get_char
						return label_on_repeat
					end
				else
					util.get_char = function()
						label_on_repeat = get_char()
						return label_on_repeat
					end
				end

				-- provide hackers
				return {
					jump = function(match, state)
						util.get_char = get_char
						require("flash.jump").jump(match, state)
					end,
					revert = function()
						util.get_char = get_char
					end,
					gen_matcher = function(k)
						local conv = k == "t"
								and function(x)
									return "." .. require("plugins.flash.query").kensaku(x)
								end
							or require("plugins.flash.query").kensaku
						local matcher = require("plugins.flash.matchers").char_matcher(conv, k == "f" or k == "t")
						return function(win, state)
							local m = matcher(win, state)
							if #m == 1 and not require("flash.repeat").is_repeat then
								label_on_repeat = state.opts.labels:sub(1, 1)
							end
							return m
						end
					end,
				}
			end

			for k, conf in pairs(motions) do
				vim.keymap.set({ "n", "x", "o" }, k, function()
					local HACK = provide_hacks() -- HACK
					require("flash").jump(vim.tbl_extend("force", {
						labels = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()[]`'=-{}~"+_]],
						mode = "char",
						matcher = HACK.gen_matcher(k),
						action = HACK.jump,
						labeler = function() end,
						highlight = {
							matches = false,
							groups = { current = require("flash.config").get().highlight.groups.label },
						},
					}, conf))
					HACK.revert()
				end)
			end

			--[[ incsearch ]]
			vim.keymap.set({ "n", "x", "o" }, ";", function()
				local cache = {}

				require("flash").jump({
					labels = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_]],
					label = { before = true, after = false },
					matcher = require("plugins.flash.matchers").incremental_matcher(nil, cache),
					labeler = function() end,
				})

				cache = {}
			end)

			--[[ search register ]]
			vim.keymap.set("n", "gn", function()
				require("flash").jump({
					labels = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_]],
					search = { multi_window = false, mode = "search" },
					label = { before = true, after = false },
					pattern = vim.fn.getreg("/"),
				})
			end)

			--[[ treesitter ]]
			vim.keymap.set("x", "v", function()
				-- ; to increment and , to decrement the selection
				require("flash").treesitter({ labels = "", jump = { autojump = true }, prompt = { enabled = false } })
			end)
		end,
		config = function()
			require("flash").setup({
				modes = {
					char = { enabled = false },
					search = { enabled = false },
					treesitter = {
						enabled = false,
						jump = { pos = "range", autojump = false },
						label = {
							before = true,
							after = true,
							style = "inline",
							rainbow = { enabled = true, shade = 3 },
						},
					},
				},
				highlight = { groups = { label = "DiagnosticError" } },
			})
		end,
	},
}
