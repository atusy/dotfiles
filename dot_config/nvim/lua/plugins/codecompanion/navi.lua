local M = {
	buf_content = {}, ---@type table<integer, string>
}

local function send_diff(chat, diff)
	chat:add_message({
		role = "user",
		content = diff,
	})
	chat:submit()
end

local function watch_changes(buf, chat)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_valid(chat.bufnr) then
		M.buf_content[buf] = nil
		return
	end

	local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
	local old = M.buf_content[buf]
	if old and old ~= content then
		local diff = vim.diff(M.buf_content[buf], content)
		send_diff(chat, diff)
	end
	if not old or vim.api.nvim_get_mode().mode ~= "i" then
		M.buf_content[buf] = content
	end
	vim.defer_fn(function()
		watch_changes(buf, chat)
	end, 5000)
end

function M.start()
	local buf = vim.api.nvim_get_current_buf()
	local prompt = {
		"#buffer",
		"をペアプロしよう。diffを受け取ったらnaviとしてコメントしてね。",
		"diffがTODOコメント関連だったら、何か提案してね。",
	}
	local chat = require("codecompanion").chat({
		fargs = prompt,
		args = table.concat(prompt, " "),
	})
	watch_changes(buf, chat)
end

M.start()

return M
