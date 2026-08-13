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
			local change = params.contentChanges and params.contentChanges[#params.contentChanges]
			if document and change and change.range == nil then
				document.text = change.text
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

return M
