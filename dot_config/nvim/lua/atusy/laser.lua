local M = {}

local function refresh()
	return true
end

local function match_head(input, candidate)
	return vim.startswith(candidate.word:lower(), input:lower())
end

local source_marks = {
	["nvim-cmdline"] = "CMD",
	["nvim-input"] = "INPUT",
	["nvim-cmdline-history"] = "HIST",
	skkelua = "SKK",
}

local function add_source(candidate)
	local client = vim.lsp.get_client_by_id(candidate.user_data.laser.client_id)
	if client then
		local mark = "[" .. (source_marks[client.name] or client.name) .. "]"
		candidate.menu = mark .. (candidate.menu and candidate.menu ~= "" and " " .. candidate.menu or "")
	end
	return candidate
end

function M.complete()
	local filter = require("laser.filter")
	local cmdline = vim.fn.mode():sub(1, 1) == "c"
	if not cmdline and vim.bo.filetype == "TelescopePrompt" then
		return
	end
	local cmdtype = cmdline and vim.fn.getcmdtype() or ""
	local input = cmdtype == "@" or cmdtype == ">" or cmdtype == "="
	require("laser").complete({
		language_id = input and "laser_input" or "vim",
		clients = { "skkelua", "nvim-cmdline", "nvim-input", "nvim-cmdline-history", "*" },
		clientOptions = {
			["*"] = {
				timeout_ms = 1000,
				filters = {
					{ kind = "matcher", callback = filter.fuzzy },
					{ kind = "sorter", callback = filter.by_score },
					{ kind = "converter", callback = filter.highlight },
					{ kind = "converter", callback = add_source },
				},
			},
			skkelua = { filters = { { kind = "converter", callback = add_source } }, refresh = refresh },
			["nvim-cmdline"] = { enabled = cmdtype == ":", refresh = refresh },
			["nvim-input"] = { enabled = input, refresh = refresh },
			["nvim-cmdline-history"] = {
				enabled = cmdtype == ":" or cmdtype == "@" or cmdtype == ">",
				refresh = refresh,
				filters = {
					{ kind = "matcher", callback = match_head },
					{ kind = "converter", callback = add_source },
				},
			},
		},
	})
end

function M.setup()
	-- Reuse the existing in-process LSP providers with laser's shared document.
	for _, name in ipairs({ "nvim-cmdline", "nvim-input", "nvim-cmdline-history" }) do
		local config = vim.lsp.config[name]
		local command = config.cmd
		vim.lsp.config(name, {
			filetypes = vim.list_extend(vim.deepcopy(config.filetypes), { "vim", "laser_input" }),
			cmd = function(dispatchers)
				local transport = command(dispatchers)
				local request = transport.request
				transport.request = function(method, params, ...)
					if method == "textDocument/completion" then
						params = vim.deepcopy(params)
						local text = vim.fn.getcmdline()
						local cursor = vim.str_byteindex(text, "utf-16", params.position.character, false)
						local start = require("laser.position").keyword_start(text, cursor)
						params.xDdc = {
							cmdType = vim.fn.getcmdtype(),
							completionType = vim.fn.exists("*getcmdcompltype") == 1 and vim.fn.getcmdcompltype() or "",
							completePos = vim.str_utfindex(text, "utf-16", start, false),
						}
					end
					return request(method, params, ...)
				end
				return transport
			end,
		})
	end

	vim.api.nvim_set_hl(0, "PmenuMatch", { link = "DiagnosticInfo" })
	vim.fn["pum#set_option"]({
		highlight_matches = "",
		preview = true,
		preview_border = "single",
		preview_width = 60,
		preview_height = 20,
	})
	local group = vim.api.nvim_create_augroup("atusy.laser", { clear = true })
	vim.api.nvim_create_autocmd({ "InsertEnter", "TextChangedI", "TextChangedP", "CmdlineEnter", "CmdlineChanged" }, {
		group = group,
		callback = M.complete,
	})
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function()
			vim.schedule(function()
				if vim.fn.mode():match("^[ic]") then
					M.complete()
				end
			end)
		end,
	})
	vim.keymap.set({ "i", "c" }, "<Tab>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#insert_relative(1)<CR>"
		end
		local before = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1)
		if vim.fn.mode() == "c" or before:match("%S$") then
			return "<Cmd>lua require('atusy.laser').complete()<CR>"
		end
		return "<Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
		return vim.fn["pum#visible"]() and "<Cmd>call pum#map#insert_relative(-1)<CR>" or "<S-Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-Y>", function()
		return vim.fn["pum#visible"]() and "<Cmd>call pum#map#confirm()<CR>" or "<C-Y>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-C>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#cancel()<CR>"
		end
		return vim.fn.mode() == "c" and "<C-U><C-C>" or "<C-C>"
	end, { expr = true })
end

return M
