local M = {}

function M.setup()
	--[=[
			Examples
				saiw[ surrounds inner word with [] and saiw] surrounds inner word with [[]]
				Similar behaviors occurs with (){}<>

				saiwj[ surrounds inner word with 「」
				srj[j] replaces 「」 with 『』
			]=]

	local t = {
		input = { "<(%w-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- from https://github.com/echasnovski/mini.surround/blob/14f418209ecf52d1a8de9d091eb6bd63c31a4e01/lua/mini/surround.lua#LL1048C13-L1048C72
		output = function()
			local emmet = require("mini.surround").user_input("Emmet")
			if not emmet then
				return nil
			end
			return require("atusy.parser.emmet").totag(emmet)
		end,
	}
	require("mini.surround").setup({
		n_lines = 100,
		mappings = {
			add = "<Plug>(s)a",
			delete = "<Plug>(s)d",
			replace = "<Plug>(s)r",
			find = "",
			find_left = "",
			highlight = "",
			update_n_lines = "",
			suffix_last = "",
			suffix_next = "",
		},
		custom_surroundings = vim.tbl_extend("force", require("plugins.mini._data").surround_recipes, {
			t = t,
		}),
	})
end

function M.lazy()
	-- lazy load mini.surround
	vim.keymap.set({ "x", "n" }, "s", function()
		vim.keymap.set({ "x", "n" }, "s", "<Plug>(s)")
		vim.keymap.set({ "x", "n" }, "<Plug>s", "<NOP>")
		M.setup()
		return "<Plug>(s)"
	end, { remap = true, expr = true })
end

return M
