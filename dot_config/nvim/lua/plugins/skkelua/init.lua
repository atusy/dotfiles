return {
	{
		"https://github.com/kjuq/skkelua.nvim",
		dependencies = { "https://github.com/skk-dev/dict" },
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
					-- Keep ddc selection and confirmation mappings available.
					keys = vim.tbl_filter(function(key)
						return key:lower() ~= "<c-y>"
							and key:lower() ~= "<tab>"
							and key:lower() ~= "<s-tab>"
							and not (vim.bo[ctx.buf].filetype == "TelescopePrompt" and key:lower() == "<cr>")
					end, keys)
					require("skkelua").config({ mappedKeys = keys })
				end,
			})

			-- 辞書
			local lazyroot = require("lazy.core.config").options.root
			local function dict(nm, repo)
				return vim.fs.joinpath(lazyroot, repo or "dict", "SKK-JISYO." .. nm)
			end
			require("skkelua").config({
				kanaTable = "rom",
				sources = { "skk_dictionary" }, -- no google_japanese_input to avoid unwanted candidates on affix
				markerHenkan = "",
				markerHenkanSelect = "",
				completion = { enabled = false }, -- ddc owns completion via atusy.lsp.skkelua
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
			require("atusy.lsp.skkelua").setup()

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
