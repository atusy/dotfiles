local M = {}

local state = {
	buf_content = {}, ---@type table<integer, string>
	diff_sizes = {}, ---@type integer[]
	chat = {}, ---@type table<integer, table>
}

local function find_75percentile(x)
	local n = #x
	if n == 0 then
		return 0
	end
	table.sort(x)
	local k = math.max(math.floor(0.75 * n), 1)
	return x[k]
end

local function send_diff(chat, diff, visible)
	chat:add_message({
		role = "user",
		content = "```diff\n" .. diff .. "\n```",
	}, { visible = visible })
	if visible then
		chat.ui:render(chat.context, chat.messages, {})
	end
	chat:submit()
end

---@param buf integer
---@return string, string | nil
local function get_buf_data(buf)
	local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
	local old = state.buf_content[buf]
	if old ~= content then
		return content, vim.diff(state.buf_content[buf], content)
	end
	return content, nil
end

local function create_autocmd(buf, chat)
	local augroup = vim.api.nvim_create_augroup("atusy-codecompanion-navi-" .. buf, {})
	local defer = { nth = 0 }
	state.buf_content[buf] = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
		group = augroup,
		buffer = buf,
		callback = function()
			local nth = defer.nth + 1
			defer.nth = nth
			vim.defer_fn(function()
				-- cleanup if the buffer is deleted
				if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_valid(chat.bufnr) then
					state.buf_content[buf] = nil
					vim.api.nvim_del_augroup_by_id(augroup)
					return
				end

				-- if new defer function is added, skip the old one
				if nth ~= defer.nth then
					return
				end

				local content, diff = get_buf_data(buf)

				-- do nothing if no diff (e.g., by undo)
				if not diff then
					return
				end

				-- record the size of the diff for statistics
				table.insert(state.diff_sizes, #diff)

				-- if the diff is large, immediately send it
				local threshold = #state.diff_sizes < 5 and 0 or find_75percentile(state.diff_sizes)
				if #diff > threshold then
					state.buf_content[buf] = content
					send_diff(chat, diff)
					return
				end

				-- if the diff is small, wait if the user adds more changes
				vim.defer_fn(function()
					if nth == defer.nth then
						state.buf_content[buf] = content
						send_diff(chat, diff)
					end
				end, 10000)
			end, 3000)
		end,
	})

	for _, b in ipairs({ buf, chat.bufnr }) do
		vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
			group = augroup,
			buffer = b,
			callback = function()
				state.buf_content[buf] = nil
				vim.api.nvim_del_augroup_by_id(augroup)
				return true
			end,
		})
	end
end

local function open_chat(buf)
	local opened_chat = state.chat[buf]
	if opened_chat and vim.api.nvim_buf_is_valid(opened_chat.bufnr) then
		if not opened_chat.ui:is_visible() then
			opened_chat.ui:open()
		end
		return opened_chat
	end

	local chat = require("codecompanion.strategies.chat").new({
		messages = {
			{
				role = "system",
				content = require("atusy.ai.prompt.gal").GAL_PAIR_PROGRAMMING.system_prompt,
				opts = { visible = false },
			},
			{
				role = "user",
				content = "#lsp\n#buffer\n\nペアプロしよ。",
				opts = { visible = true },
			},
		},
		context = require("codecompanion.utils.context").get(buf, {}),
		opts = { ignore_system_prompts = true },
	})
	chat:submit()
	state.chat[buf] = chat
	return chat
end

function M.start()
	local buf = vim.api.nvim_get_current_buf()
	local chat = open_chat(buf)
	create_autocmd(buf, chat)
end

return M
