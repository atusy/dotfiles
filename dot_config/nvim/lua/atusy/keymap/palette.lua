local M = {
	star = "☆",
	init = true,
}

function M.set_item(item)
	local space = " " -- U+00A0
	local mode = item.mode
	local lhs = M.star
		.. item.lhs:gsub(" ", space) -- replace with U+00A0 to avoid showing <Space>
		.. space
		.. space -- append two spaces to avoid potential waiting
	local rhs = item.rhs or lhs
	local opts = vim.tbl_deep_extend("keep", item.opts or {}, { desc = "" })
	vim.keymap.set(mode, lhs, rhs, opts)
end

--- update needs be ran on demand so that mapping takes no time on init
function M.update()
	local failed = {}
	if M.init then
		for _, item in pairs(require("atusy.keymap.palette_items")) do
			local ok, res = pcall(M.set_item, item)
			if not ok then
				table.insert(failed, { res, item })
			end
		end
		M.init = false
	end
	for _, item in pairs(M.items) do
		local ok, res = pcall(M.set_item, item)
		if not ok then
			table.insert(failed, { res, item })
		end
	end
	M.items = failed
	if #failed > 0 then
		vim.notify(
			"failed to update some items on update command platte. Examine `require('atusy.keymap.palette').items`"
		)
	end
	return failed
end

function M.add_item(mode, lhs, rhs, opts)
	table.insert(M.items, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
end

M.items = {}

return M
