local function commandline_pre(mode)
	local buf = vim.api.nvim_get_current_buf()
	local opts = vim.fn["ddc#custom#get_buffer"]()
	vim.fn["pum#set_local_option"](mode, "min_height", vim.o.pumheight)
	vim.api.nvim_create_autocmd("User", {
		group = vim.api.nvim_create_augroup("atusy.ddc.commandline_pre", {}),
		pattern = "DDCCmdlineLeave",
		once = true,
		desc = "revert temporary settings",
		callback = function()
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_call(buf, function()
					vim.fn["ddc#custom#set_buffer"](opts or vim.empty_dict())
				end)
			end
		end,
	})
	local enabledIf = string.format(
		[[getcmdline() =~# "^\\(%s\\)" ? v:true : v:false]],
		table.concat({ "!", "[Mm]ake", "lmake", "Gin", "GinBuffer" }, [[\\|]])
	)
	vim.fn["ddc#custom#patch_buffer"]("sourceOptions", {
		file = { forceCompletionPattern = [[(^e\s+|\S/\S*)]] },
		fish = { enabledIf = enabledIf, minAutoCompleteLength = 0 },
		xonsh = { enabledIf = enabledIf, minAutoCompleteLength = 0 },
		zsh = { enabledIf = enabledIf, minAutoCompleteLength = 0 },
		shell_history = { enabledIf = [[getcmdline()[0] == "!" ? v:true : v:false]] },
		-- ["_"] = mode == ":" and { keywordPattern = "[0-9a-zA-Z_:#-]*" },
	})

	-- Enable command line completion
	vim.fn["ddc#enable_cmdline_completion"]()
end

local function config()
	-- general
	vim.keymap.set({ "i", "c" }, "<Tab>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#insert_relative(+1)<CR>"
		end
		if vim.api.nvim_get_mode().mode == "c" then
			return "<Cmd>call ddc#map#manual_complete()<CR>"
		end
		local col = vim.fn.col(".")
		local line = vim.fn.getline(".")
		if col > 1 and type(line) == "string" and string.match(vim.fn.strpart(line, col - 2), "%s") == nil then
			return "<Cmd>call ddc#map#manual_complete()<CR>"
		end
		return "<Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<s-tab>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#insert_relative(-1)<CR>"
		end
		return "<S-Tab>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-Y>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#confirm()<CR>"
		end
		return "<C-Y>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-C>", function()
		if vim.fn["pum#visible"]() then
			return "<Cmd>call pum#map#cancel()<CR>"
		end
		if vim.api.nvim_get_mode().mode == "c" then
			return "<C-U><C-C>"
		end
		return "<C-C>"
	end, { expr = true })
	vim.keymap.set({ "i", "c" }, "<C-X><CR>", function()
		vim.notify(vim.inspect(vim.fn["pum#current_item"]()))
	end)

	-- on cmdline
	for _, lhs in pairs({ ":", "/", "?" }) do
		vim.keymap.set({ "n", "x" }, lhs, function()
			pcall(commandline_pre, lhs)
			return lhs
		end, { expr = true })
	end
	vim.keymap.set("c", "<C-X><C-M>", function()
		local t = vim.fn.getcmdtype()
		local line = vim.fn.getcmdline()
		local match = function(x)
			return x == line
		end
		if vim.fn["pum#current_item"]().menu == "RECENT" then
			match = function(x)
				return x == line or vim.startswith(x, line .. " ") or vim.startswith(x, line .. "! ")
			end
		end
		for i = -1, -vim.fn.histnr(t), -1 do
			if match(vim.fn.histget(t, i)) then
				vim.fn.histdel(t, i)
				vim.cmd("wshada!")
				return
			end
		end
	end)

	local augroup = vim.api.nvim_create_augroup("atusy-ddc-enable", {})

	-- configure
	vim.fn["ddc#custom#load_config"](vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "init.ts"))

	-- lazy enable
	vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter" }, {
		group = augroup,
		callback = function(ctx)
			local ft = vim.bo[ctx.buf].filetype
			if ft == "TelescopePrompt" then
				return
			end
			vim.fn["ddc#enable"]()
			vim.fn["pum#set_option"]({
				preview = true,
				preview_border = "single",
				preview_width = 60,
				preview_height = 20,
			})
			-- vim.fn["popup_preview#enable"]()
			return true
		end,
	})
end

return {
	{ "https://github.com/Shougo/ddc.vim", config = config },
	-- ui
	{ "https://github.com/Shougo/pum.vim" },
	-- source
	{
		"https://github.com/atusy/ddc-source-nvim-lsp",
		lazy = false,
		config = function()
			vim.lsp.config("*", {
				capabilities = require("ddc_source_nvim_lsp").make_client_capabilities(),
			})
		end,
	},
	{ "https://github.com/Shougo/ddc-ui-pum" },
	-- filter
	{ "https://github.com/tani/ddc-fuzzy" },
	-- matcher
	{ "https://github.com/Shougo/ddc-filter-matcher_head" },
	-- converter
	{ "https://github.com/Shougo/ddc-filter-converter_truncate_abbr" },
	-- dictionaries for ddc (install only)
	{ "https://github.com/dwyl/english-words", lazy = true },
}
