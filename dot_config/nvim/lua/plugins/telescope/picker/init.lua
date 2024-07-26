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

local qfhistory = {}

function M.quickfix(opts)
	opts = opts or {}

	local nth, id = (function()
		if type(opts.nth) == "number" and 1 <= opts.nth and opts.nth <= #qfhistory then
			return opts.nth, qfhistory[opts.nth]
		end
		local _id = opts.id or vim.fn.getqflist({ id = 0 }).id
		table.insert(qfhistory, _id)
		return #qfhistory, _id
	end)()

	local function update_qfhistory(prompt_bufnr)
		local prompt = require("telescope.actions.state").get_current_picker(prompt_bufnr):_get_prompt()
		if prompt == "" then
			return
		end
		for i = nth, #qfhistory do
			qfhistory[i + 1] = nil
		end
		require("telescope.actions").send_to_qflist(prompt_bufnr)
		nth = #qfhistory + 1
		qfhistory[nth] = vim.fn.getqflist({ id = 0 }).id
	end

	local actions = require("telescope.actions.mt").transform_mod({
		prev_qflist = function(prompt_bufnr)
			update_qfhistory(prompt_bufnr)
			if nth > 1 then
				M.quickfix({ nth = math.max(1, nth - 1) })
			end
		end,
		next_qflist = function(prompt_bufnr)
			update_qfhistory(prompt_bufnr)
			if nth < #qfhistory then
				M.quickfix({ nth = nth + 1 })
			end
		end,
	})

	local attach_mappings = opts.attach_mappings
	opts.attach_mappings = function(prompt_bufnr, map)
		if attach_mappings then
			attach_mappings(prompt_bufnr, map)
		end
		map({ "i" }, "<C-Left>", actions.prev_qflist)
		map({ "i" }, "<C-Right>", actions.next_qflist)
		return true
	end

	local _opts = vim.tbl_extend("force", opts, { id = id })
	_opts.nth = nil
	require("telescope.builtin").quickfix(_opts)
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
			if not x.error then
				-- something wrong that I have never met
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
			vim.lsp.util.jump_to_location(locs[1], "utf-8", false)
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
	local implementation = false
	for _, c in pairs(clients) do
		if c.server_capabilities.implementationProvider then
			implementation = true
		end
	end
	if implementation then
		return gtd(opts, bufnr, "textDocument/implementation", params, function(resps)
			local handler = gen_gtd_handler(opts, extract_locations(resps))
			gtd(opts, bufnr, "textDocument/definition", params, handler)
		end)
	end

	-- textDocument/definition
	local definition = false
	for _, c in pairs(clients) do
		if c.server_capabilities.implementationProvider then
			definition = true
		end
	end
	if definition then
		return gtd(opts, bufnr, "textDocument/definition", params, nil)
	end

	-- enhanced gf
	require("atusy.misc").open_cfile()
end

return M
