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

local keymaps_default_text = {
	fern = "'fern-action ",
	["gin-status"] = "'gin-action ",
	["gin-log"] = "'gin-action ",
}

function M.keymaps(opts)
	require("atusy.lazy").load_all()
	require("atusy.keymap.palette").update()
	require("telescope.builtin").keymaps(opts or {
		modes = { vim.api.nvim_get_mode().mode },
		default_text = vim.b.telescope_keymaps_default_text or keymaps_default_text[vim.bo.filetype] or require(
			"atusy.keymap.palette"
		).star,
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
	for _, resp in pairs(resps) do
		if vim.tbl_islist(resp.result) then
			for _, i in pairs(resp.result or {}) do
				table.insert(locs, i)
			end
		else
			table.insert(locs, resp.result)
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
function M.gtd(opts, bufnr, method, params, handler)
	vim.lsp.buf_request_all(
		bufnr or 0,
		method or "textDocument/definition",
		params or vim.lsp.util.make_position_params(0, "utf-8"),
		handler or gen_gtd_handler(opts or {})
	)
end

--- go to implementation, definition, or file
function M.gti(opts, bufnr, _, params, _)
	M.gtd(opts, bufnr, "textDocument/implementation", params, function(resps)
		local handler = gen_gtd_handler(opts, extract_locations(resps))
		M.gtd(opts, bufnr, "textDocument/definition", params, handler)
	end)
end

return M
