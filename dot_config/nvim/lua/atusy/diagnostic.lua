local M = {}

function M.toggle_severity(keys, severities)
	local config = vim.diagnostic.config()
	if not config then
		return config
	end

	for _, key in pairs(keys) do
		-- format current severity into table<string, boolean>
		local severity = {} ---@type table<string, boolean>
		local init = type(config[key]) == "boolean" and config[key] or false
		for _, nm in ipairs(vim.diagnostic.severity) do
			severity[nm] = init
		end
		if type(config[key]) == "table" then
			for _, s in pairs(config[key].severity) do
				if type(s) == "number" then
					severity[vim.diagnostic.severity[s]] = true
				else
					severity[s] = true
				end
			end
		end

		-- toggle current severity
		for _, s in ipairs(severities) do
			if type(s) == "number" then
				s = vim.diagnostic.severity[s]
			end
			severity[s] = not severity[s]
		end

		-- update severity
		config[key] = type(config[key]) == "table" and config[key] or {}
		config[key].severity = {}
		for k, v in pairs(severity) do
			if v then
				table.insert(config[key].severity, k)
			end
		end
	end

	-- apply
	vim.diagnostic.config(config)

	-- return applied config
	return vim.diagnostic.config()
end

function M.underlined_severities()
	local config = vim.diagnostic.config().underline
	if config == nil or type(config) == "boolean" then
		return config and vim.diagnostic.severity or {}
	end
	return config.severity
end

---@param count number? positive to next, negative to previous
---@param opts table? options to pass to `vim.diagnostic.jump`
function M.jump_to_underlined(count, opts)
	vim.diagnostic.jump(vim.tbl_extend("force", opts or {}, {
		severity = M.underlined_severities(),
		count = count,
	}))
end

return M
