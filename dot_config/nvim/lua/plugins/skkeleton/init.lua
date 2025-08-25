local function set_mapped_keys(exceptions)
  -- stylua: ignore
  local default = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "!", '"', "#", "$", "%", "&", "'", "(", ")", ",", ".", "/", ";", ":", "]", "@", "[", "-", "^", "\\", ">", "?", "_", "+", "*", "}", "`", "{", "=", "~", "<lt>", "<Bar>", "<BS>", "<C-h>", "<CR>", "<Space>", "<C-q>", "<PageUp>", "<PageDown>", "<C-j>", "<C-g>", "<Esc>" }
	local _exceptions = {}
	for _, v in pairs(exceptions) do
		_exceptions[v] = true
	end
	local maps = {}
	for _, m in pairs(default) do
		if _exceptions[m] ~= true then
			table.insert(maps, m)
		end
	end
	vim.g["skkeleton#mapped_keys"] = maps
end

return {
	{
		"https://github.com/vim-skk/skkeleton", -- denops
		dependencies = { "https://github.com/vim-denops/denops.vim" },
		config = function()
			vim.keymap.set({ "i", "c", "t" }, "<C-J>", "<Plug>(skkeleton-enable)")
			local register_kanatable = vim.fn["skkeleton#register_kanatable"]
			register_kanatable("rom", require("plugins.skkeleton.azik"))
			register_kanatable("rom", {
				["\\"] = "disable",
				["<s-l>"] = "zenkaku",
				["'"] = "katakana",
				["z "] = { "　", "" },
				["z."] = { "……", "" },
				[";"] = { "っ", "" },
				[":"] = { "：", "" },
			})

			local augroup = vim.api.nvim_create_augroup("atusy.skkeleton", {})
			vim.api.nvim_create_autocmd("User", {
				group = augroup,
				pattern = "skkeleton-enable-pre",
				callback = function(ctx)
					-- filetypeに応じた一部キーの無効化
					local ft = vim.bo[ctx.buf].filetype
					local exceptions = {}
					if ft == "TelescopePrompt" then
						table.insert(exceptions, "<CR>")
					end
					set_mapped_keys(exceptions)

					-- ddcによるskkelton補完
					local ddc_ok, ddc_config = pcall(function()
						local config = vim.fn["ddc#custom#get_buffer"]()
						vim.fn["ddc#custom#patch_buffer"]("sources", { "skkeleton" })
						return config
					end)

					if not ddc_ok then
						vim.notify(ddc_config, vim.log.levels.ERROR)
					end

					vim.api.nvim_create_autocmd("User", {
						pattern = "skkeleton-disable-pre",
						once = true,
						callback = function()
							if ddc_ok then
								vim.fn["ddc#custom#set_buffer"](ddc_config)
							end
						end,
					})
				end,
			})

			-- 辞書
			local lazyroot = require("lazy.core.config").options.root
			local function dict(nm, repo)
				return vim.fs.joinpath(lazyroot, repo or "dict", "SKK-JISYO." .. nm)
			end
			vim.fn["skkeleton#config"]({
				sources = { "deno_kv" }, -- no google_japanese_input to avoid unwanted candidates on affix
				markerHenkan = "",
				markerHenkanSelect = "",
				databasePath = vim.fs.joinpath(vim.fn.stdpath("cache"), "skkeleton-dictionary.sqlite3"),
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
					dict("jawiki", "jawiki-kana-kanji-dict"),
					dict("emoji"),
				},
			})

			-- init
			vim.fn["skkeleton#initialize"]()

			-- system-specific settings
			if vim.loop.os_uname().sysname == "Linux" then
				local focused = false
				vim.api.nvim_create_autocmd({ "FocusGained", "InsertEnter", "User" }, {
					group = augroup,
					callback = function(ctx)
						focused = true
						if ctx.event == "User" and ctx.file ~= "skkeleton-enable-pre" then
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
