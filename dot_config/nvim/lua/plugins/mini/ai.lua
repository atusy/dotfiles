local M = {}

function M.setup()
	--[[
			Examples:
				vi[ selects inside single bracket and vi] selects inside double brackets.
				(){}<> works similary
			
				vij[ selects inside 「」. 
				I intorduce some hacks because `custom_textobjects` does not support multiple characters as keys.
			]]
	local DATA = require("plugins.mini._data")
	local custom_textobjects = {}
	for k, v in pairs(DATA.surround_recipes) do
		custom_textobjects[k] = v.input
	end

	local gen_spec = require("mini.ai").gen_spec
	custom_textobjects.d = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })
	custom_textobjects.D = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })
	custom_textobjects.B = gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }) -- for markdown fenced codeblock
	custom_textobjects.J = (function()
		-- e.g., iJ selects inside japanese brackets
		local ret = {}
		for _, v in pairs(DATA.japanese_brackets) do
			table.insert(ret, v.left .. "().-()" .. v.right)
		end
		return { ret }
	end)()

	require("nvim-treesitter-textobjects")

	local mappings = {
		around = "a",
		inside = "i",
		around_next = "an",
		inside_next = "in",
		around_last = "al",
		inside_last = "il",
		goto_left = "g[",
		goto_right = "g]",
	}

	local modes = {
		goto_left = { "n", "x", "o" },
		goto_right = { "n", "x", "o" },
	}

	require("mini.ai").setup({
		n_lines = 100,
		mappings = mappings,
		custom_textobjects = custom_textobjects,
	})

	-- repatable operations on Japanese brackets by using `?`
	-- must be done after `mini.ai.setup()`
	for action, lhs in pairs(mappings) do
		if lhs ~= "" then
			local mode = modes[action] or { "o", "x" }

			-- mappings for various Japanese brackets
			for k, v in pairs(DATA.japanese_brackets) do
				-- e.g., vim.keymap.set({"x", "o"}, "ij[", "i?「<cr>」<cr>", { remap = true })
				vim.keymap.set(
					mode,
					lhs .. "j" .. k,
					lhs .. "?" .. v.left .. "<cr>" .. v.right .. "<cr>",
					{ remap = true }
				)
			end

			-- mappings for Japanese brackets near the cursor
			vim.keymap.set(mode, lhs .. "jb", lhs .. "J", { remap = true })
		end
	end
end

function M.lazy()
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = vim.api.nvim_create_augroup("atusy-mini-ai", {}),
		callback = function()
			M.setup()
		end,
		once = true,
	})
end

return M
