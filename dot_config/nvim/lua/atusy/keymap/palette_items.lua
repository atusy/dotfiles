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
			vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = 0 }))
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
			vim.system({
				"find",
				require("lazy.core.config").options.root,
				"-name",
				"'*.ts'",
				"-exec",
				"deno",
				"cache",
				"--reload",
				"{}",
				"+",
			})
		end,
	},
}
