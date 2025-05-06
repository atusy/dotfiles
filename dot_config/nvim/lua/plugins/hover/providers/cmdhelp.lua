local function help(cmd)
	local ok, p = pcall(vim.system, { cmd, "--help" })
	if not ok then
		return {}
	end
	local obj = p:wait()
	local res = obj.stdout
	if not res or res == "" or res == "\n" then
		res = obj.stderr
		if not res or res == "" or res == "\n" then
			return {}
		end
	end
	return vim.fn.split(res, "\n")
end

require("hover").register({
	name = "cmdhelp",
	enabled = function(bufnr)
		return true
	end,
	execute = function(opts, done)
		local node = vim.treesitter.get_node({ bufnr = opts.bufnr, pos = { opts.pos[1] - 1, opts.pos[2] } })
		while node do
			if node:type() == "command_name" then
				local lines = help(vim.treesitter.get_node_text(node, opts.bufnr))
				done(#lines > 0 and { lines = lines, filetype = "text" } or false)
				return
			end
			node = node:parent()
		end
		done(false)
	end,
})
