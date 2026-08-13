local M = {}

local error_codes = vim.lsp.protocol.ErrorCodes

local function response_error(code, message)
	return vim.lsp.rpc.rpc_response_error(code, message)
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
