local function git_exclude(path)
	local gitdir = vim.fs.find(".git", { upward = true })[1]

	if not gitdir then
		vim.notify("not in git repository")
	end

	local git_info_exclude = vim.fs.joinpath(gitdir, "info", "exclude")
	local file = (function()
		if vim.uv.fs_stat(vim.fs.joinpath(gitdir, "info", "exclude")) then
			return io.open(git_info_exclude, "a")
		end
		vim.fn.mkdir(vim.fs.dirname(git_info_exclude), "p")
		return io.open(git_info_exclude, "w")
	end)()

	if not file then
		vim.notify("failed to open " .. git_info_exclude)
		return
	end
	pcall(function()
		file:write(path)
	end)
	file:close()
end

return {
	--[[ window ]]
	{ mode = "n", lhs = "window: equalize horizontally", rhs = "<Cmd>horizontal wincmd =<CR>" },
	{ mode = "n", lhs = "window: equalize vertically", rhs = "<Cmd>vertical wincmd =<CR>" },

	--[[ clipboard ]]
	{ mode = "n", lhs = "clipboard: cwd", rhs = "<Cmd>let @+=getcwd()<CR>" },
	{ mode = "n", lhs = "clipboard: abs path of %", rhs = '<Cmd>let @+=expand("%:p")<CR>' },
	{ mode = "n", lhs = "clipboard: abs path of %:h", rhs = '<Cmd>let @+=expand("%:p:h")<CR>' },

	--[[ open ]]
	{ mode = "n", lhs = "open: cwd", rhs = "<Cmd>lua vim.ui.open('.')<CR>" },
	{ mode = "n", lhs = "open: %:h", rhs = "<Cmd>lua vim.ui.open(vim.fn.expand('%:h'))<CR>" },

	--[[ treesitter ]]
	{ mode = "n", lhs = "treesitter: inspect tree", rhs = "<Cmd>lua vim.treesitter.inspect_tree()<CR>" },
	{
		mode = "n",
		lhs = "redraw!",
		rhs = [[<Cmd>call setline(1, getline(1, '$'))<CR><Cmd>silent undo<CR><Cmd>redraw!<CR>]],
		opts = {
			desc = "with full rewrite of the current buffer, which may possibly fixes broken highlights by treesitter",
		},
	},

	--[[ lsp ]]
	{
		mode = "n",
		lhs = "lsp: restart attached clients",
		rhs = function()
			for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
				client:stop()
			end
			vim.cmd("edit!")
		end,
	},
	{
		mode = "n",
		lhs = "lsp: add workspace folder",
		rhs = "<Cmd>lua = vim.lsp.buf.add_workspace_folder()<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: remove workspace folder",
		rhs = "<Cmd>lua = vim.lsp.buf.remove_workspace_folder()<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: list workspace folders",
		rhs = "<Cmd>lua = vim.lsp.buf.list_workspace_folders()<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: loglevel to info",
		rhs = "<Cmd>lua vim.lsp.log.set_level('info')<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: loglevel to debug",
		rhs = "<Cmd>lua vim.lsp.log.set_level('debug')<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: loglevel to off",
		rhs = "<Cmd>lua vim.lsp.log.set_level('off')<CR>",
	},
	{
		mode = "n",
		lhs = "lsp: open logfile",
		rhs = "<Cmd>lua vim.cmd('e ' .. vim.lsp.get_log_path())<CR>",
	},

	--[[ diagnostic ]]
	{
		mode = "n",
		lhs = "diagnostic: toggle info and hint",
		rhs = function()
			require("atusy.diagnostic").toggle_severity({ "virtual_text", "underline" }, { "HINT", "INFO" })
		end,
	},
	{
		mode = "n",
		lhs = "diagnostic: set loclist",
		rhs = [[<Cmd>lua vim.diagnostic.setloclist()<CR>]],
	},

	--[[ highlight ]]
	{
		mode = "n",
		lhs = "highlight: toggle transparency",
		rhs = function()
			require("atusy.highlight").change_background()
		end,
	},

	--[[ plugin management ]]
	{
		mode = "n",
		lhs = "denops: reload cache",
		rhs = function()
			require("plugins.denops.utils").cache_plugin(nil, true)
		end,
	},

	--[[ git ]]
	{
		mode = "n",
		lhs = "git amend --no-edit",
		rhs = function()
			vim.system({ "git", "commit", "--amend", "--no-edit", "--quiet" }, nil, function() end)
		end,
	},
	{
		mode = "n",
		lhs = "git push",
		rhs = function()
			vim.system({ "git", "push", "--quiet", "origin", "HEAD" }, {
				stdout = true,
				stderr = true,
			}, function() end)
		end,
	},
	{
		mode = "n",
		lhs = "git push --force",
		rhs = function()
			vim.system(
				{ "git", "push", "--quiet", "--force-with-lease", "--force-if-includes", "origin", "HEAD" },
				nil,
				function() end
			)
		end,
	},
	{
		mode = "n",
		lhs = "git: ignore % locally",
		rhs = function()
			git_exclude(vim.fn.expand("%"))
		end,
	},
	{
		mode = "n",
		lhs = "git: ignore %:h locally",
		rhs = function()
			git_exclude(vim.fn.expand("%:h"))
		end,
	},
}
