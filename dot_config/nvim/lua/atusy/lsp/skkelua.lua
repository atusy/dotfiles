-- Adapt skkelua's public completion API to the same LSP transport used by
-- command-line providers. The upstream LSP assumes the current Insert cursor
-- and owns native completion; this provider uses the synchronized LSP document.
local M = {}
local candidates = {}

function M.complete(params, document)
	local skk = require("skkelua")
	local empty = { isIncomplete = true, items = {} }
	if not skk.is_enabled() or skk.phase() ~= "input:okurinasi" or not document then
		return empty
	end
	local preedit = skk.get_pre_edit()
	if preedit == "" or skk.get_prefix() == "" then
		return empty
	end
	local line = vim.split(document.text, "\n", { plain = true })[params.position.line + 1] or ""
	local column = vim.str_byteindex(line, "utf-16", params.position.character, false)
	local before = line:sub(1, column)
	if not vim.endswith(before, preedit) then
		return empty
	end
	local range = {
		start = { line = params.position.line, character = vim.str_utfindex(before, "utf-16", #before - #preedit) },
		["end"] = params.position,
	}
	local ranks = {}
	for _, entry in ipairs(skk.get_ranks()) do
		ranks[entry[1]] = entry[2]
	end
	local entries = skk.get_completion_result()
	table.sort(entries, function(a, b)
		return a[1] < b[1]
	end)
	local items, seen = {}, {}
	for _, entry in ipairs(entries) do
		for _, candidate in ipairs(entry[2]) do
			local word = candidate:gsub(";.*", "")
			if entry[1]:sub(1, 1) == ">" then
				word = word:gsub("^>", "")
			elseif entry[1]:sub(-1) == ">" then
				word = word:gsub(">$", "")
			end
			if not seen[word] then
				seen[word] = true
				local data = { midasi = entry[1], word = candidate }
				candidates[word] = data
				items[#items + 1] = {
					label = word,
					sortText = #items + 1, -- dictionary ordinal until ranks are applied
					detail = candidate:match(";(.*)$"),
					textEdit = { range = range, newText = word },
					data = data,
				}
			end
		end
	end
	-- Preserve dictionary order when ranks tie.
	table.sort(items, function(a, b)
		local ar, br = ranks[a.data.word] or 0, ranks[b.data.word] or 0
		return ar == br and a.sortText < b.sortText or ar > br
	end)
	for i, item in ipairs(items) do
		item.sortText = string.format("%06d", i)
	end
	return { isIncomplete = true, items = items }
end

function M.complete_buffer(params, document)
	-- ddc resolves an unnamed buffer to cwd/, while Neovim opens file://.
	-- Only accept that alias for the current unnamed buffer; named and scratch
	-- documents must continue to use their synchronized LSP snapshots.
	if not document and vim.api.nvim_buf_get_name(0) == "" then
		local alias = vim.uri_from_fname(vim.fn.fnamemodify("", ":p"))
		if params.textDocument.uri == alias then
			document = { text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") }
		end
	end
	return M.complete(params, document)
end

function M.on_complete_done(item)
	if item.__sourceName ~= "skkelua" and item.__sourceName ~= "skkelua-cmdline" then
		return
	end
	-- The command-line source intentionally drops LSP metadata; abbr retains
	-- the server label even when word includes a command-line prefix.
	local lspitem = vim.tbl_get(item, "user_data", "lspitem")
	if type(lspitem) == "string" then
		local ok, decoded = pcall(vim.json.decode, lspitem)
		lspitem = ok and decoded or nil
	end
	local data = type(lspitem) == "table" and lspitem.data or candidates[item.abbr]
	if data then
		require("skkelua").complete_callback(data.midasi, data.word)
	end
end

function M.setup()
	local rpc = require("atusy.lsp.ddc_completion")
	vim.lsp.config("skkelua-cmdline", {
		cmd = rpc.command(M.complete),
		filetypes = { "ddc_skkelua" },
		root_dir = vim.uv.cwd(),
	})
	vim.lsp.enable("skkelua-cmdline")
	local group = vim.api.nvim_create_augroup("atusy.skkelua.lsp", {})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "skkelua-enable-post",
		callback = function()
			candidates = {}
			vim.lsp.start({ name = "skkelua", cmd = rpc.command(M.complete_buffer) })
		end,
	})
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "PumCompleteDone",
		callback = function()
			M.on_complete_done(vim.g["pum#completed_item"] or {})
		end,
	})
end

return M
