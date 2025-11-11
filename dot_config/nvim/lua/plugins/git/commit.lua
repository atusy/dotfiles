local function leave(tab, buf, augroup)
	vim.schedule(function()
		pcall(vim.api.nvim_del_augroup_by_id, augroup)
		if vim.api.nvim_buf_is_valid(buf) then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
		if not vim.api.nvim_tabpage_is_valid(tab) then
			return
		end
		if vim.api.nvim_get_current_tabpage() == tab then
			vim.cmd("tabclose")
		end
	end)
end

---@param buf number A buffer of commit message
---@param args string[] A list of extra arguments to be passed to git commit
local function commit(buf, args)
	local res = vim.system({ "git", "commit", unpack(args or {}), "--quiet", "--file", "-" }, {
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

local function get_message(ref)
	local res = vim.system({ "git", "log", "-n", "1", "--format=%s%n%n%b", ref }):wait()
	if res.code == 0 then
		local message = {}
		for line in res.stdout:gmatch("[^\n]*") do
			table.insert(message, line)
		end
		return message
	end
	vim.notify(res.stderr, vim.log.levels.ERROR)
end

---@param opts? { args: string[] }
local function exec(opts)
	opts = vim.tbl_deep_extend("keep", opts or {}, { args = {} })

	-- init UI
	vim.cmd([[GinDiff! ++opener=tabnew --staged]])
	vim.cmd([[GinBuffer ++opener=topleft\ vsplit graph -n 20 | setlocal number]])
	vim.cmd([[GinStatus ++opener=aboveleft\ split]])
	vim.cmd(([[aboveleft split %s]]):format(vim.fn.tempname() .. ".gitcommit"))

	-- get ui data
	local tab = vim.api.nvim_get_current_tabpage()
	local buf = vim.api.nvim_get_current_buf()

	-- autocmd
	local augroup = vim.api.nvim_create_augroup(tostring(buf), {})
	vim.api.nvim_create_autocmd({ "TabClosed", "BufHidden", "BufDelete" }, {
		group = augroup,
		callback = function(ctx)
			if ctx.event ~= "TabClosed" or ctx.file == tab then
				leave(tab, buf, augroup)
			end
		end,
	})

	-- mappings
	vim.keymap.set("n", "<Plug>(C-S)<C-Q>", function()
		if commit(buf, opts.args) == 0 then
			leave(tab, buf, augroup)
		end
	end, { buffer = buf })

	local n = -1
	local function replace_message(delta)
		n = n + delta
		if n < 0 then
			n = -1
		end
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, n < 0 and {} or get_message("HEAD~" .. tostring(n)))
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
