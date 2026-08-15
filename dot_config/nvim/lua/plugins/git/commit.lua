local function leave(tab, buf, augroup)
	vim.schedule(function()
		-- separate pcall to ensure all are attempted
		pcall(vim.api.nvim_del_augroup_by_id, augroup)
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		pcall(function()
			vim.cmd.tabclose({ args = { vim.api.nvim_tabpage_get_number(tab) } })
		end)
	end)
end

---@param buf number A buffer of commit message
---@param args string[] A list of extra arguments to be passed to git commit
---@param root string The repository root
local function commit(buf, args, root)
	local res = vim.system({ "git", "commit", unpack(args or {}), "--quiet", "--file", "-" }, {
		cwd = root,
		stdin = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
	}):wait()
	if res.code ~= 0 then
		vim.notify("Failed to commit:", vim.log.levels.ERROR)
	end
	if res.stdout and res.stdout:match("%w") then
		vim.notify(res.stdout)
	end
	if res.stderr and res.stderr:match("%w") then
		vim.notify(res.stderr, vim.log.levels.ERROR)
	end
	return res.code
end

---@param ref string A revision to read
---@param root string The repository root
local function get_message(ref, root)
	local res = vim.system({ "git", "log", "-n", "1", "--format=%s%n%n%b", ref }, { cwd = root }):wait()
	if res.code == 0 then
		local message = {}
		for line in res.stdout:gmatch("[^\n]*") do
			table.insert(message, line)
		end
		return message
	end
	vim.notify(res.stderr, vim.log.levels.ERROR)
end

local function git_root()
	local res = vim.system({ "git", "rev-parse", "--show-toplevel" }):wait()
	local root = vim.trim(res.stdout or "")
	if res.code == 0 and root ~= "" then
		return root
	end
	vim.notify(res.stderr or "Failed to resolve Git repository", vim.log.levels.ERROR)
end

---@param opts? { args: string[] }
local function exec(opts)
	opts = vim.tbl_deep_extend("keep", opts or {}, { args = {} })
	local root = git_root()
	if not root then
		return
	end

	-- init UI
	vim.cmd.GinDiff({ bang = true, args = { "++opener=tabnew", "--staged" } })
	vim.cmd.GinBuffer({ args = { "++opener=topleft vsplit", "graph", "-n", "20" } })
	vim.api.nvim_set_option_value("number", true, { win = 0, scope = "local" })
	vim.cmd.GinStatus({ args = { "++opener=aboveleft split" } })
	local name = "." .. vim.fs.basename(vim.fn.tempname()) .. ".gitcommit"
	vim.cmd.split({ mods = { split = "aboveleft" }, args = { vim.fs.joinpath(root, name) } })
	pcall(vim.treesitter.start) -- manually start to avoid unexpected skip (often happens after :LazySync)

	-- get ui data
	local tab = vim.api.nvim_get_current_tabpage()
	local buf = vim.api.nvim_get_current_buf()

	-- options
	vim.bo[buf].buftype = "nofile"

	-- autocmd
	local augroup = vim.api.nvim_create_augroup(tostring(buf), {})
	vim.api.nvim_create_autocmd({ "TabClosed", "BufHidden", "BufDelete" }, {
		group = augroup,
		buffer = buf,
		callback = function(ctx)
			if ctx.event ~= "TabClosed" or ctx.file == tab then
				leave(tab, buf, augroup)
			end
		end,
	})

	-- mappings
	vim.keymap.set("n", "<Plug>(C-S)<C-Q>", function()
		if commit(buf, opts and opts.args or {}, root) == 0 then
			leave(tab, buf, augroup)
		end
	end, { buffer = buf })

	local n = -1
	local function replace_message(delta)
		n = n + delta
		if n < 0 then
			n = -1
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, n < 0 and {} or get_message("HEAD~" .. tostring(n), root))
	end
	vim.keymap.set("n", "<C-O>", function()
		replace_message(1)
	end, { buffer = buf })
	vim.keymap.set("n", "<C-I>", function()
		replace_message(-1)
	end, { buffer = buf })
end

return {
	exec = exec,
}
