local M = {}
local filter = require("laser.filter")
local fuzzy_matcher = filter.fuzzy_matcher()
local score_sorter = filter.score_sorter()

local function text_last_score_sorter(a, b)
	local text = vim.lsp.protocol.CompletionItemKind.Text
	local a_text = a.user_data.laser.item.kind == text
	local b_text = b.user_data.laser.item.kind == text
	if a_text ~= b_text then
		return not a_text
	end
	return score_sorter(a, b)
end

local path_completion_types = {
	file = true,
	dir = true,
	file_in_path = true,
	dir_in_path = true,
}

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
	local cmdline = vim.fn.mode():sub(1, 1) == "c"
	if not cmdline and vim.bo.filetype == "TelescopePrompt" then
		return
	end
	local cmdtype = cmdline and vim.fn.getcmdtype() or ""
	local completion_type = cmdline and vim.fn.getcmdcompltype() or ""
	local input = cmdtype == "@" or cmdtype == ">" or cmdtype == "="
	local skk_enabled = require("skkelua").is_enabled()
	if skk_enabled and require("skkelua").phase() == "henkan" then
		-- Conversion uses skkelua's Space/asdfjkl menu, including pending responses.
		require("laser").close()
		return
	end
	local clients
	if skk_enabled then
		clients = { "skkelua" }
	elseif cmdtype == ":" then
		clients = { "nvim-cmdline", "*", "nvim-cmdline-history" }
	elseif cmdtype == "@" or cmdtype == ">" then
		clients = { "nvim-input", "*", "nvim-cmdline-history" }
	elseif cmdtype == "=" then
		clients = { "nvim-input" }
	else
		clients = { "*" }
	end
	require("laser").complete({
		language_id = input and "laser_input" or "vim",
		clients = clients,
		menu = { preview = { border = "single", max_width = 60, max_height = 20 } },
		clientOptions = {
			["*"] = {
				timeout_ms = 1000,
				filters = {
					{ kind = "matcher", callback = fuzzy_matcher },
					{ kind = "sorter", callback = text_last_score_sorter },
					{ kind = "converter", callback = add_source },
				},
			},
			skkelua = {
				enabled = skk_enabled,
				filters = { { kind = "converter", callback = add_source } },
				refresh = refresh,
				max_items = 30,
			},
			["nvim-cmdline"] = {
				enabled = cmdtype == ":" and not path_completion_types[completion_type],
				refresh = refresh,
			},
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
						params.xNvimCmdline = {
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
	local group = vim.api.nvim_create_augroup("plugins.laser", { clear = true })
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "skkelua-handled",
		callback = function()
			-- Candidate paging need not change the buffer text.
			if require("skkelua").is_enabled() and require("skkelua").phase() == "henkan" then
				require("laser").close()
			end
		end,
	})
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
	-- Menu actions edit text, so <expr> mappings run them through <Cmd>.
	local laser = require("laser")
	vim.keymap.set({ "i", "c" }, "<Tab>", function()
		if laser.visible() then
			return "<Cmd>lua require('laser').select(1)<CR>"
		end
		local before = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1)
		if vim.fn.mode() == "c" or before:match("%S$") then
			return "<Cmd>lua require('plugins.laser.completion').complete()<CR>"
		end
		return "<Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
		return laser.visible() and "<Cmd>lua require('laser').select(-1)<CR>" or "<S-Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-Y>", function()
		-- Confirmation through the SKK adapter lets skkelua learn the candidate.
		return laser.visible() and "<Cmd>lua require('atusy.lsp.skkelua').confirm()<CR>" or "<C-Y>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-C>", function()
		if laser.visible() then
			return "<Cmd>lua require('laser').cancel()<CR>"
		end
		return vim.fn.mode() == "c" and "<C-U><C-C>" or "<C-C>"
	end, { expr = true })
end

return M
