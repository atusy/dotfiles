vim.loader.enable()

-- configurations independent from plugins
require("atusy")

-- skipped builtins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_fzf = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_remote_plugins = 1

--[[ lazy.nvim ]]
-- local lazypath = require("atusy.utils").datapath .. "/lazy/lazy.nvim"
local lazypath = "/home/atusy/ghq/github.com/folke/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then ---@diagnostic disable-line: undefined-field
	require("atusy.lazy").install(lazypath)
end

vim.opt.runtimepath:prepend(lazypath)
require("lazy").setup("plugins", { ---@diagnostic disable-line: different-requires
	change_detection = { enabled = false },
	performance = {
		cache = { enabled = false }, -- let vim.loader.enable() do the job
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
	dev = {
		path = function(plugin)
			local path, cnt = string.gsub(plugin.url, "^https://(.*)", vim.uv.os_homedir() .. "/ghq/%1") ---@diagnostic disable-line: undefined-field
			if cnt == 1 then
				if not vim.uv.fs_stat(path) then
					vim.system({ "git", "clone", plugin.url, "--", path }):wait()
				end
				return path:gsub("%.git$", "")
			end

			-- fallback to default
			return "~/projects/" .. plugin.name
		end,
	},
})
