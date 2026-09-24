return {
	{
		"https://github.com/atusy/skkelua.nvim",
		branch = "feat/completion-extension-api",
		config = function()
			vim.keymap.set({ "i", "c", "t" }, "<C-J>", "<Plug>(skkelua-enable)")
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
					-- Keep laser selection and confirmation mappings available.
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
					vim.keymap.set(mode, "<C-g>", require("atusy.lsp.skkelua").cancel_keys, {
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
			require("atusy.lsp.skkelua").allow_fed_backspace()
			require("atusy.lsp.skkelua").setup({
				trigger = function()
					require("plugins.laser.completion").complete()
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
