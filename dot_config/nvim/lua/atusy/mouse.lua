local M = {}

function M.toggle_left_drag()
	for _, m in pairs(vim.api.nvim_get_keymap("n")) do
		if m.lhs == "<LeftDrag>" then
			if m.rhs == "" then
				vim.keymap.del("n", "<LeftDrag>")
				vim.keymap.del("n", "<LeftRelease>")
			end
			return
		end
	end
	vim.keymap.set("n", "<LeftDrag>", "<NOP>")
	vim.keymap.set("n", "<LeftRelease>", "<NOP>")
end

return M
