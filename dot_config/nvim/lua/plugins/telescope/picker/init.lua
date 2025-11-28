local M = {}

function M.outline()
	local picker = require("telescope.builtin").treesitter
	if vim.tbl_contains({ "markdown" }, vim.bo.filetype) then
		local ok, aerial = pcall(function()
			require("aerial") -- ensure lazy loading
			return require("telescope._extensions").manager.aerial.aerial
		end)
		picker = ok and aerial or picker
	end
	picker({ sorter = require("plugins.telescope.sorter").filter_only_sorter() })
end

function M.keymaps(opts)
	require("atusy.lazy").load_all()
	require("atusy.keymap.palette").update()
	require("telescope.builtin").keymaps(opts or {
		modes = { vim.api.nvim_get_mode().mode },
		default_text = vim.b.telescope_keymaps_default_text or require("atusy.keymap.palette").star,
	})
end

function M.help_tags(opts)
	require("atusy.lazy").load_all()
	require("telescope.builtin").help_tags(opts or { lang = "ja" })
end

function M.locations(opts, locations, title)
	opts = opts or {}
	local conf = require("telescope.config").values
	require("telescope.pickers")
		.new(opts, {
			prompt_titile = title or "Locations",
			finder = require("telescope.finders").new_table({
				results = locations,
				entry_maker = require("telescope.make_entry").gen_from_quickfix(opts),
			}),
			previewer = conf.qflist_previewer(opts),
			sorter = conf.generic_sorter(opts),
			push_cursor_on_edit = true,
			push_tagstack_on_edit = true,
		})
		:find()
end

local function extract_locations(resps, locs)
	locs = locs and { unpack(locs) } or {}
	local listed = {}

	local function get_key(x)
		local result = x.result or x
		local range = result.targetRange or result.range
		if range == nil then
			if not x.error and not vim.bo.filetype == "lua" then
				-- something wrong that I have never met
				-- in Lua, this may happen when asking for a location on string
				vim.notify(vim.inspect(x))
			end
			return
		end
		return string.format(
			"%i;%i;%i;%i",
			range["start"]["line"],
			range["start"]["character"],
			range["end"]["line"],
			range["end"]["character"]
		)
	end

	for _, loc in pairs(locs) do
		local key = get_key(loc)
		if key then
			listed[get_key(loc)] = true
		end
	end

	for _, resp in pairs(resps) do
		if vim.islist(resp.result) then
			for _, result in pairs(resp.result or {}) do
				local key = get_key(result)
				if key and not listed[key] then
					listed[key] = true
					table.insert(locs, result)
				end
			end
		else
			local key = get_key(resp)
			if key and not listed[key] then
				listed[key] = true
				table.insert(locs, resp.result)
			end
		end
	end
	return locs
end

local function gen_gtd_handler(opts, locs)
	return function(resps)
		locs = extract_locations(resps, locs)
		if #locs == 0 then
			require("atusy.misc").open_cfile()
		elseif #locs == 1 then
			vim.lsp.util.show_document(locs[1], "utf-8")
		else
			M.locations(opts, vim.lsp.util.locations_to_items(locs, "utf-8"), "LSP definitions")
		end
	end
end

--- go to definition or file
local function gtd(opts, bufnr, method, params, handler)
	vim.lsp.buf_request_all(
		bufnr or 0,
		method or "textDocument/definition",
		params or vim.lsp.util.make_position_params(0, "utf-8"),
		handler or gen_gtd_handler(opts or {})
	)
end

--- go to implementation, definition, or file
function M.gtd(opts, bufnr, _, params, _)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	-- textDocument/implementation
	for _, c in pairs(clients) do
		if c.server_capabilities.implementationProvider then
			return gtd(opts, bufnr, "textDocument/implementation", params, function(resps)
				local handler = gen_gtd_handler(opts, extract_locations(resps))
				gtd(opts, bufnr, "textDocument/definition", params, handler)
			end)
		end
	end

	-- textDocument/definition
	for _, c in pairs(clients) do
		if c.server_capabilities.definitionProvider then
			return gtd(opts, bufnr, "textDocument/definition", params, nil)
		end
	end

	-- enhanced gf
	require("atusy.misc").open_cfile()
end

---git_status picker with branch and traffic info in the prompt title
function M.git_status()
	local function _make_title()
		local branch = vim.fn["gin#component#branch#unicode"]()
		if branch == "" or branch == nil then
			local alt = vim.system({ "git", "branch", "--points-at", "HEAD", "--all", "--format=%(refname:short)" })
				:wait()
			if alt.code ~= 0 then
				return nil
			end
			local title = alt.stdout:gsub("\n", " ")
			return title
		end
		local traffic = vim.fn["gin#component#traffic#unicode"]()
		local title = branch .. " " .. traffic
		return title ~= " " and title or nil
	end
	local function make_title()
		local ok, title = pcall(_make_title)
		return ok and title or nil
	end
	require("telescope.builtin").git_status({
		prompt_title = make_title(), -- initial title can be nil and thus requires updates by autocmd
		sorter = require("plugins.telescope.sorter").filter_only_sorter(),
		attach_mappings = function(prompt_bufnr, _)
			local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

			-- highlight the prompt title
			local ns = vim.api.nvim_get_hl_ns({ winid = picker.layout.prompt.border.winid })
			if ns == 0 then
				ns = vim.api.nvim_create_namespace("atusy.telescope_git_status")
				vim.api.nvim_win_set_hl_ns(picker.layout.prompt.border.winid, ns)
			end
			vim.api.nvim_set_hl(ns, "TelescopePromptTitle", { link = "Title" })

			-- create autocmds
			local augroup = vim.api.nvim_create_augroup("atusy.telescope_git_status", { clear = true })
			vim.api.nvim_create_autocmd("WinClosed", {
				group = augroup,
				callback = function()
					local win = vim.api.nvim_get_current_win()
					if win == picker.prompt_win then
						vim.api.nvim_del_augroup_by_id(augroup)
					end
				end,
			})
			vim.api.nvim_create_autocmd("User", {
				group = augroup,
				pattern = "GinComponentPost",
				callback = function()
					local title = make_title()
					if title then
						picker.layout.prompt.border:change_title(title)
					end
				end,
			})
			return true
		end,
	})
end

return M
