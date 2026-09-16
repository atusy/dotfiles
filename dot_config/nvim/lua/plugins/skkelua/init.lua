return {
	{
		"https://github.com/kjuq/skkelua.nvim",
		dev = true, -- use the completion-extension-api work in ghq
		dependencies = { "https://github.com/skk-dev/dict" },
		config = function()
			vim.keymap.set({ "i", "c", "t" }, "<C-J>", "<Plug>(skkelua-enable)")
			vim.keymap.set({ "i", "c" }, "<Plug>(atusy-skkelua-cancel-completion)", function()
				local pum = vim.fn["pum#_get"]()
				local inserted = pum.cursor > 0 and pum.current_word ~= ""
				if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" and require("skkelua").is_enabled() then
					if inserted then
						-- skkelua's guard blocks the <BS> keys used by pum's
						-- cancellation. Restore the selected span directly instead.
						local pos = vim.api.nvim_win_get_cursor(0)
						vim.cmd([[call extend(pum#_get(), #{cursor: -1, current_word: ''})]])
						vim.api.nvim_buf_set_text(
							0,
							pos[1] - 1,
							pum.startcol - 1,
							pos[1] - 1,
							pos[2],
							{ pum.orig_input }
						)
						vim.api.nvim_win_set_cursor(0, { pos[1], pum.startcol - 1 + #pum.orig_input })
					end
				end
				vim.fn["pum#map#cancel"]()
				-- An unselected menu has no inserted candidate to undo.
				-- Cancel the SKK conversion on the same key press too.
				if not inserted then
					require("skkelua").handle("handleKey", { key = "<C-g>" })
				end
			end)

			local register_kanatable = require("skkelua").register_kanatable
			register_kanatable("rom", require("plugins.skkelua.azik"), true)
			register_kanatable("rom", {
				["\\"] = "disable",
				["<s-l>"] = "zenkaku",
				["'"] = "katakana",
				["z "] = { "　", "" },
				["z."] = { "……", "" },
				[";"] = { "っ", "" },
				[":"] = { "：", "" },
			})

			local augroup = vim.api.nvim_create_augroup("atusy.skkelua", {})
			vim.api.nvim_create_autocmd("User", {
				group = augroup,
				pattern = "skkelua-enable-pre",
				callback = function(ctx)
					local keys = require("skkelua").get_default_mapped_keys()
					-- Keep pum selection and confirmation mappings available.
					keys = vim.tbl_filter(function(key)
						return key:lower() ~= "<c-y>"
							and key:lower() ~= "<c-g>"
							and key:lower() ~= "<tab>"
							and key:lower() ~= "<s-tab>"
							and not (vim.bo[ctx.buf].filetype == "TelescopePrompt" and key:lower() == "<cr>")
					end, keys)
					require("skkelua").config({ mappedKeys = keys })
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				group = augroup,
				pattern = "skkelua-enable-post",
				callback = function(ctx)
					local mode = vim.fn.mode()
					mode = mode == "n" and "i" or mode
					if mode ~= "i" and mode ~= "c" then
						return
					end
					-- skkelua has already saved this mode's buffer-local maps.
					-- Its disable path restores them, revealing the global map too.
					if mode == "c" then
						vim.keymap.set(mode, "<C-g>", "<Plug>(C-G)", { buffer = ctx.buf, nowait = true })
					end
					vim.keymap.set(mode, "<Plug>(C-G)", function()
						if vim.fn.exists("*pum#visible") == 1 and vim.fn["pum#visible"]() then
							return "<Plug>(atusy-skkelua-cancel-completion)"
						end
						return "<Cmd>lua require('skkelua').handle('handleKey', { key = '<C-g>' })<CR>"
					end, {
						buffer = ctx.buf,
						expr = true,
						nowait = true,
						desc = "Cancel completion or return SKK conversion to its reading",
					})
				end,
			})

			-- 辞書
			local lazyroot = require("lazy.core.config").options.root
			local function dict(nm, repo)
				return vim.fs.joinpath(lazyroot, repo or "dict", "SKK-JISYO." .. nm)
			end
			require("skkelua").config({
				kanaTable = "rom",
				immediatelyCancel = false, -- return a conversion candidate to its reading first
				sources = { "skk_dictionary" }, -- no google_japanese_input to avoid unwanted candidates on affix
				markerHenkan = "",
				markerHenkanSelect = "",
				completion = { enabled = false }, -- laser owns completion via atusy.lsp.skkelua
				userDictionary = vim.fn.expand("~/.skkeleton"), -- retain the existing SKK user dictionary
				lowercaseMap = { [":"] = ";" },
				globalDictionaries = {
					dict("L"),
					dict("propernoun"),
					dict("geo"),
					dict("station"),
					dict("hukugougo"),
					dict("jinmei"),
					dict("fullname"),
					dict("edict2"),
					dict("assoc"),
					-- dict("jawiki", "jawiki-kana-kanji-dict"), -- TODO: needs to download from GH Releases
					dict("emoji"),
				},
			})

			-- init
			require("atusy.lsp.skkelua").setup({
				trigger = function()
					require("atusy.laser").complete()
				end,
			})

			-- system-specific settings
			if vim.loop.os_uname().sysname == "Linux" then
				local focused = false
				vim.api.nvim_create_autocmd({ "FocusGained", "InsertEnter", "User" }, {
					group = augroup,
					callback = function(ctx)
						focused = true
						if ctx.event == "User" and ctx.file ~= "skkelua-enable-pre" then
							return
						end
						vim.system({ "fcitx5-remote", "-s", "keyboard-us" }):wait()
					end,
				})
				vim.api.nvim_create_autocmd({ "FocusLost", "VimLeave" }, {
					group = augroup,
					callback = function()
						focused = false
						vim.defer_fn(function()
							if not focused then
								vim.system({ "fcitx5-remote", "-s", "skk" }):wait()
							end
						end, 500)
					end,
				})
			end
		end,
	},
	{ "https://github.com/skk-dev/dict", lazy = true },
	{ "https://github.com/tokuhirom/jawiki-kana-kanji-dict", lazy = true },
}
