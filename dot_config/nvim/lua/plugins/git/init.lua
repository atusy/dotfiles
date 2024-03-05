local add_item = require("atusy.keymap.palette").add_item

-- gitsigns settings
local function setup_gitsigns()
	local has_num = vim.o.number or vim.o.relativenumber

	require("gitsigns").setup({
		signcolumn = not has_num,
		numhl = has_num,
		current_line_blame_opts = { delay = 150 },
		on_attach = function(buf)
			local function save_and(x, cmd)
				return "<Plug>(save)" .. (cmd or "<Cmd>") .. "Gitsigns " .. x .. "<CR>"
			end
			vim.keymap.set("n", "<Plug>(C-G)a", save_and("stage_buffer"), { buffer = buf }) -- add buf
			vim.keymap.set("n", "<Plug>(C-G)r", save_and("reset_buffer"), { buffer = buf }) --reset buf
			vim.keymap.set("n", "<Plug>(C-G)<C-H>", save_and("preview_hunk"), { buffer = buf }) -- preview hunk
			vim.keymap.set("n", "<Plug>(C-G)<u>", save_and("undo_stage_hunk"), { buffer = buf }) -- undo add hunk
			vim.keymap.set(
				{ "n", "x" },
				"<Plug>(C-G)<C-A>",
				save_and("stage_hunk", ":"),
				{ buffer = buf, silent = true }
			)
			vim.keymap.set({ "n", "x" }, "<Plug>(C-G)<C-R>", function()
				require("gitsigns").reset_hunk()

				-- lazy save to avoid buf remains modified
				local function cb(ctx)
					if not vim.bo[ctx.buf].modified then
						vim.api.nvim_del_autocmd(ctx.id)
					elseif ctx.buf == buf then
						vim.cmd([[silent up]])
					end
				end
				vim.api.nvim_create_autocmd("User", { pattern = "GitSignsUpdate", callback = cb, once = true })
				vim.api.nvim_create_autocmd("CursorMoved", { callback = cb, once = true })
			end, { buffer = buf, desc = "reset hunk and ensure buf be up to date" })
		end,
	})

	-- keymaps
	vim.keymap.set("n", "<Down>", function()
		return vim.wo.diff and "]c" or "<Cmd>Gitsigns next_hunk<CR><Cmd>Gitsigns preview_hunk_inline<CR>"
	end, { expr = true })

	vim.keymap.set("n", "<Up>", function()
		return vim.wo.diff and "[c" or "<Cmd>Gitsigns prev_hunk<CR><Cmd>Gitsigns preview_hunk_inline<CR>"
	end, { expr = true })

	-- command palette
	add_item("n", "gitsigns: based on cWORD ref", function()
		require("gitsigns").change_base(vim.fn.expand("<cWORD>"), true)
	end)
	add_item("n", "gitsigns: based on HEAD", [[<Cmd>lua require("gitsigns").reset_base(true)<CR>]])
	add_item("n", "gitsigns: diff to qflist", [[<Cmd>lua require("gitsigns").setqflist("all")<CR>]])
	add_item("n", "gitsigns: toggle word diff", [[<Cmd>Gitsigns toggle_word_diff<CR>]])
	add_item("n", "gitsigns: toggle line blame", function()
		vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { link = "Comment" }) -- be lazy
		require("gitsigns").toggle_current_line_blame()
	end)
end

-- gin
local function setup_gin()
	vim.g.gin_patch_disable_default_mappings = true
	local has_delta = vim.fn.executable("delta") == 1
	-- disable delta as <CR> won't work
	local processor = nil
	if has_delta then
		processor = "delta --no-gitconfig --color-only" -- also requires tsnode-marker to reproduce highlights
		vim.g.gin_diff_persistent_args = { "++processor=" .. processor }
	end
	local augroup = vim.api.nvim_create_augroup("atusy.gin", {})
	vim.api.nvim_create_autocmd("BufReadCmd", {
		group = augroup,
		pattern = { "gin://*", "ginedit://*", "ginlog://*", "gindiff://*" },
		callback = function(ctx)
			vim.keymap.set("n", "<F5>", "<Cmd>call gin#util#reload()<CR>", { buffer = ctx.buf })
			if ctx.match:match("^ginedit://") then
				vim.keymap.set("n", "<Plug>(C-G)<C-A>", "<Plug>(gin-diffget-r)", { buffer = ctx.buf }) -- git add
				vim.keymap.set("n", "<Plug>(C-G)<C-R>", "<Plug>(gin-diffget-l)", { buffer = ctx.buf }) -- git reset
			else
				if ctx.match:match("^ginlog://") then
					require("plugins.git.log").map(ctx)
				end
				vim.keymap.set("n", "a", function()
					require("telescope.builtin").keymaps({ default_text = "gin-action " })
				end, { buffer = ctx.buf })
			end
		end,
	})
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = { "gitcommit", "gitrebase" },
		callback = function()
			vim.g.gin_proxy_apply_without_confirm = 1
			vim.keymap.set("ca", "q!", function()
				if
					vim.fn.getcmdtype() == ":"
					and vim.fn.getcmdline() == "q!"
					and vim.api.nvim_buf_get_commands(0, {}).Cancel
				then
					return "up <Bar> Cancel"
				end
				return "q!"
			end, { buffer = true, expr = true })
		end,
	})

	-- keymaps
	vim.keymap.set("n", "<Plug>(C-G)<C-L>", function()
		vim.cmd("wincmd v")
		local nm = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(0))
		if nm ~= "" and vim.uv.fs_stat(nm) then ---@diagnostic disable-line: undefined-field
			require("plugins.git.log").exec_graph("-n", "200", "--", "%")
		else
			require("plugins.git.log").exec_graph("-n", "200")
		end
	end, { desc = "git graph" })
	vim.keymap.set(
		"n",
		"<Plug>(C-G)l",
		[[<C-W>v<Cmd>lua require("plugins.git.log").exec_graph("-n", "200")<CR>]],
		{ desc = "git graph" }
	)
	vim.keymap.set("n", "<Plug>(C-G)<C-P>", "<Cmd>GinPatch ++opener=tabnew %<CR>")
	vim.keymap.set("n", "<Plug>(C-G)<C-D>", "<Cmd>GinDiff -- %<CR>")
	vim.keymap.set("n", "<Plug>(C-G)d", "<Cmd>GinDiff -- .<CR>")
	vim.keymap.set("n", "<Plug>(C-G)<C-U>", "<Cmd>Gin reset -- %<CR>") -- unstage buf
	vim.keymap.set("n", "<Plug>(C-G)<C-Space>", [[<Cmd>lua require("plugins.git.commit").exec()<CR>]]) -- commit
	vim.keymap.set("n", "<Plug>(C-G)<C-F>", ":.GinBrowse<CR>") -- i.e. open file in hosting site
	vim.keymap.set("x", "<Plug>(C-G)<C-F>", ":GinBrowse<CR>")

	--- Yank permalink iff the current buffer is commited and the commit is pushed
	local function yank()
		if vim.bo.modified then
			vim.notify("Must save", vim.log.levels.ERROR)
			return
		end
		local bufname = vim.api.nvim_buf_get_name(0)
		local commited = vim.system({ "git", "diff", "--quiet", "--", bufname }):wait().code == 0
		if not commited then
			vim.notify("Must commit: " .. bufname, vim.log.levels.ERROR)
			return
		end
		local pushed = vim.system({ "git", "branch", "-r", "--contains", "HEAD" }, {}):wait().code == 0
		if not pushed then
			vim.notify("Must push HEAD", vim.log.levels.ERROR)
			return
		end
		local mode = vim.api.nvim_get_mode().mode
		return ":" .. (mode == "nromal" and "." or "") .. "GinBrowse ++yank=+ -n --permalink<CR>"
	end
	vim.keymap.set("n", "<Plug>(C-G)<C-Y>", yank, { expr = true })
	vim.keymap.set("x", "<Plug>(C-G)<C-Y>", yank, { expr = true })

	-- command palette
	add_item("n", "git amend", [[<Cmd>lua require("plugins.git.commit").exec({ args = {"--amend" } })<CR>]]) -- commit
	add_item("n", "git amend --no-edit", ":Gin ++wait commit --amend --no-edit ")
	add_item("n", "git rebase -i", ":Gin rebase --rebase-merge -i ")
	add_item(
		"n",
		"git rebase --onto A B C",
		":Gin rebase --rebase-merge --onto ",
		{ desc = "AにBからCまでの差分を乗せる" }
	)
	add_item("n", "git push", ":Gin ++wait push origin HEAD ")
	add_item("n", "git push --force", ":Gin ++wait push --force-with-lease --force-if-includes origin HEAD ")
	add_item("n", "git diff", ":GinDiff ")
	add_item("n", "git diff --ignore-all-space", ":GinDiff --ignore-all-space ")
end

-- return
return {
	{
		"https://github.com/lambdalisue/gin.vim",
		dependencies = { "https://github.com/vim-denops/denops.vim" },
		config = setup_gin,
	},
	{ "https://github.com/lewis6991/gitsigns.nvim", config = setup_gitsigns },
}
