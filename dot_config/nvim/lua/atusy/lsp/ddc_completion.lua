local M = {}

local error_codes = vim.lsp.protocol.ErrorCodes

local function response_error(code, message)
	return vim.lsp.rpc.rpc_response_error(code, message)
end

local function text_before_cursor(params, document)
	if document == nil or type(document.text) ~= "string" then
		return ""
	end
	local character = params.position and params.position.character or 0
	local ok, byte_index = pcall(vim.str_byteindex, document.text, "utf-16", character, false)
	if not ok then
		return document.text
	end
	return document.text:sub(1, byte_index)
end

local function completion_items(words)
	local items = {}
	for _, word in ipairs(words or {}) do
		if type(word) == "string" then
			local item = { label = word }
			if vim.endswith(word, "/") then
				item.insertText = word:sub(1, -2)
			end
			table.insert(items, item)
		end
	end
	return { items = items }
end

local function utf16_index(text, byte_offset)
	return vim.str_utfindex(text, "utf-16", byte_offset, false)
end

local function completion_edit(input, word)
	local start_byte = #input
	for index = 1, #input + 1 do
		if vim.startswith(word:lower(), input:sub(index):lower()) then
			start_byte = index - 1
			break
		end
	end
	return {
		range = {
			start = { line = 0, character = utf16_index(input, start_byte) },
			["end"] = { line = 0, character = utf16_index(input, #input) },
		},
		newText = word,
	}
end

local function position_byte_offset(text, position)
	local lines = vim.split(text, "\n", { plain = true })
	local offset = 0
	for line = 1, position.line do
		offset = offset + #(lines[line] or "") + 1
	end
	local current = lines[position.line + 1] or ""
	local ok, column = pcall(vim.str_byteindex, current, "utf-16", position.character, false)
	return offset + (ok and column or #current)
end

local function apply_content_changes(text, changes)
	for _, change in ipairs(changes or {}) do
		if change.range == nil then
			text = change.text
		else
			local start_offset = position_byte_offset(text, change.range.start)
			local end_offset = position_byte_offset(text, change.range["end"])
			text = text:sub(1, start_offset) .. change.text .. text:sub(end_offset + 1)
		end
	end
	return text
end

---@param api { getcompletion: fun(input: string, completion_type: string): string[] }
---@return fun(params: table, document: table?): table
function M.make_input_provider(api)
	return function(params, document)
		local metadata = params.xDdc or {}
		local completion_type = metadata.cmdType == "=" and "expression" or metadata.completionType
		if completion_type == nil or completion_type == "" then
			return { items = {} }
		end
		local ok, words = pcall(api.getcompletion, text_before_cursor(params, document), completion_type)
		return completion_items(ok and words or {})
	end
end

---@param api { gethistory: fun(cmd_type: string, limit: integer): string[], isdirectory: fun(path: string): boolean, isfile: fun(path: string): boolean }
---@param limit integer
---@return fun(params: table, document: table?): table
function M.make_history_provider(api, limit)
	return function(params, document)
		local metadata = params.xDdc or {}
		local ok, histories = pcall(api.gethistory, metadata.cmdType or ":", limit)
		if not ok then
			return { items = {} }
		end

		local input = text_before_cursor(params, document)
		local complete_pos = metadata.completePos or 0
		local ok_index, complete_byte = pcall(vim.str_byteindex, input, "utf-16", complete_pos, false)
		complete_byte = ok_index and complete_byte or #input
		local prefix = input:find(" ", 1, true) and input:sub(1, complete_byte) or nil
		local items = {}
		for _, history in ipairs(histories or {}) do
			local single_line = type(history) == "string" and not history:find("[\r\n]")
			local path_matches = metadata.completionType ~= "dir" or api.isdirectory(history)
			path_matches = path_matches
				and (metadata.completionType ~= "file" or api.isdirectory(history) or api.isfile(history))
			local prefix_matches = prefix == nil or vim.startswith(history, prefix)
			if single_line and path_matches and prefix_matches then
				table.insert(items, { label = prefix and history:sub(complete_byte + 1) or history })
			end
		end
		return { items = items }
	end
end

local excluded_cmd_types = {
	["/"] = true,
	["?"] = true,
	[">"] = true,
	["="] = true,
	["@"] = true,
}

---@param api { getcompletion: fun(input: string, completion_type: string): string[] }
---@return fun(params: table, document: table?): table
function M.make_cmdline_provider(api)
	return function(params, document)
		local metadata = params.xDdc or {}
		if excluded_cmd_types[metadata.cmdType] then
			return { items = {} }
		end

		local input = text_before_cursor(params, document)
		local ok, words = pcall(api.getcompletion, input, "cmdline")
		if not ok then
			return { items = {} }
		end

		local complete_str = input:sub((metadata.completePos or 0) + 1)
		local items = {}
		for _, word in ipairs(words or {}) do
			if complete_str:sub(1, 2) == "no" and vim.startswith(input, "set") then
				word = "no" .. word
			end
			local help_matches = not vim.startswith(input, "help ")
				or vim.startswith(word:lower(), input:gsub("^help%s+", ""):lower())
			if help_matches then
				local item = completion_items({ word }).items[1]
				item.textEdit = completion_edit(input, word)
				item.textEdit.newText = item.insertText or word
				table.insert(items, item)
			end
		end
		return { items = items }
	end
end

---@param api table
---@return { name: string, filetype: string, provider: function }[]
function M.configurations(api)
	return {
		{ name = "nvim-cmdline", filetype = "ddc_cmdline", provider = M.make_cmdline_provider(api) },
		{ name = "nvim-input", filetype = "ddc_input", provider = M.make_input_provider(api) },
		{
			name = "nvim-cmdline-history",
			filetype = "ddc_cmdline_history",
			provider = M.make_history_provider(api, 1000),
		},
	}
end

local function default_api()
	return {
		getcompletion = function(input, completion_type)
			return vim.fn.getcompletion(input, completion_type)
		end,
		gethistory = function(cmd_type, limit)
			local histories = {}
			for index = -1, -math.min(limit, vim.fn.histnr(cmd_type)), -1 do
				table.insert(histories, vim.fn.histget(cmd_type, index))
			end
			return histories
		end,
		isdirectory = function(path)
			return vim.fn.isdirectory(path) == 1
		end,
		isfile = function(path)
			return vim.fn.filereadable(path) == 1
		end,
	}
end

---@param dispatchers vim.lsp.rpc.Dispatchers
---@param opts { provider: fun(params: table, document: table?): table? }
---@return vim.lsp.rpc.Client
function M.create(dispatchers, opts)
	local closing = false
	local next_request_id = 0
	local pending = {}
	local documents = {}

	local function settle(id, err, result)
		local request = pending[id]
		if request == nil or request.settled or closing then
			return
		end
		request.settled = true
		pending[id] = nil
		pcall(request.callback, err, result, id)
		if request.notify_reply_callback then
			pcall(request.notify_reply_callback, id)
		end
	end

	local function terminate()
		if closing then
			return
		end
		closing = true
		pending = {}
		if dispatchers.on_exit then
			dispatchers.on_exit(0, 0)
		end
	end

	local client = {}

	function client.is_closing()
		return closing
	end

	function client.request(method, params, callback, notify_reply_callback)
		if closing then
			return false, nil
		end

		next_request_id = next_request_id + 1
		local id = next_request_id
		pending[id] = {
			callback = callback,
			notify_reply_callback = notify_reply_callback,
			settled = false,
		}

		local captured_params = vim.deepcopy(params or {})
		local uri = captured_params.textDocument and captured_params.textDocument.uri
		local captured_document = uri and vim.deepcopy(documents[uri]) or nil
		vim.schedule(function()
			if pending[id] == nil or closing then
				return
			end

			if method == "initialize" then
				settle(id, nil, {
					capabilities = {
						completionProvider = {},
						textDocumentSync = { openClose = true, change = 2 },
					},
				})
			elseif method == "shutdown" then
				settle(id, nil, nil)
			elseif method == "textDocument/completion" then
				local ok, result = pcall(opts.provider, captured_params, captured_document)
				if ok then
					settle(id, nil, result or { items = {} })
				else
					settle(id, response_error(error_codes.InternalError, tostring(result)), nil)
				end
			else
				settle(id, response_error(error_codes.MethodNotFound), nil)
			end
		end)

		return true, id
	end

	function client.notify(method, params)
		if closing then
			return false
		end
		params = params or {}
		if method == "textDocument/didOpen" then
			local document = params.textDocument
			documents[document.uri] = {
				uri = document.uri,
				version = document.version,
				text = document.text,
			}
		elseif method == "textDocument/didChange" then
			local document = documents[params.textDocument.uri]
			if document then
				document.text = apply_content_changes(document.text, params.contentChanges)
				document.version = params.textDocument.version
			end
		elseif method == "textDocument/didClose" then
			documents[params.textDocument.uri] = nil
		elseif method == "$/cancelRequest" then
			local id = params.id
			if pending[id] then
				settle(id, response_error(error_codes.RequestCancelled), nil)
			end
		elseif method == "exit" then
			terminate()
		end
		return true
	end

	client.terminate = terminate
	return client
end

---@param provider fun(params: table, document: table?): table?
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.Client
function M.command(provider)
	return function(dispatchers)
		return M.create(dispatchers, { provider = provider })
	end
end

function M.setup()
	local names = {}
	for _, provider_config in ipairs(M.configurations(default_api())) do
		local name = provider_config.name
		vim.lsp.config(name, {
			cmd = M.command(provider_config.provider),
			filetypes = { provider_config.filetype },
			root_dir = vim.uv.cwd(),
			reuse_client = function(client)
				return client.name == name
			end,
		})
		table.insert(names, name)
	end
	vim.lsp.enable(names)
end

return M
