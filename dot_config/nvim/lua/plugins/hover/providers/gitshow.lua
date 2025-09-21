local function execute(opts, done)
	local label = ""

	if vim.bo.filetype == "gitrebase" then
		local node = vim.treesitter.get_node({ bufnr = opts.bufnr, pos = { opts.pos[1] - 1, opts.pos[2] } })
		while node do
			if node:type() == "operation" then
				print(vim.treesitter.get_node_text(node, opts.bufnr, {}))
				break
			end
			node = node:parent()
		end
		if not node then
			return done(false)
		end

		local message = false
		for n in node:iter_children() do
			local t = n:type()
			if t == "label" then
				label = vim.treesitter.get_node_text(n, opts.bufnr, {})
			elseif t == "message" then
				message = true
			end
		end

		if not message then
			return done(false)
		end
	else
		label = vim.fn.expand("<cword>")
	end

	local obj = vim.system({ "git", "show", "--patch", "--stat", label }, {}):wait()

	if obj.code > 0 or not obj.stdout then
		return done(false)
	end

	local stdout, cnt = obj.stdout:gsub("\n\n", "\n \n")
	while cnt > 0 do
		stdout, cnt = stdout:gsub("\n\n", "\n \n")
	end
	local lines = {}
	for line in stdout:gmatch("[^\n]+") do
		table.insert(lines, line == " " and "" or line)
	end

	return done({ lines = lines, filetype = "diff" })
end

return {
	name = "gitshow",
	enabled = function(bufnr)
		return true
	end,
	execute = execute,
}
