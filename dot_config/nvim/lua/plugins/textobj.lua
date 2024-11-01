local function getchar()
	return vim.fn.nr2char(vim.fn.getchar())
end

local function japanize_bracket(dict, callbacks)
	return function()
		local char = getchar()

		if callbacks[char] then
			return callbacks[char](dict)
		end
		if dict[char] then
			return dict[char]
		end

		vim.notify("mini.ai/surround does not support j" .. char, vim.log.levels.ERROR)
		return nil
	end
end

local BRACKETS = {
	["{"] = {
		input = { "%b{}", "^.().*().$" },
		output = { left = "{", right = "}" },
	},
	["}"] = {
		input = { "%b{}", "^.%{().*()%}.$" },
		output = { left = "{{", right = "}}" },
	},
	["("] = {
		input = { "%b()", "^.().*().$" },
		output = { left = "(", right = ")" },
	},
	[")"] = {
		input = { "%b()", "^.%(().*()%).$" },
		output = { left = "((", right = "))" },
	},
	["["] = {
		input = { "%b[]", "^.().*().$" },
		output = { left = "[", right = "]" },
	},
	["]"] = {
		input = { "%b[]", "^.%[().*()%].$" },
		output = { left = "[[", right = "]]" },
	},
	["<"] = {
		input = { "%b<>", "^.().*().$" },
		output = { left = "<", right = ">" },
	},
	[">"] = {
		input = { "%b[]", "^.<().*()>.$" },
		output = { left = "<<", right = ">>" },
	},
}

local recipes = vim.tbl_extend("force", {}, BRACKETS)

recipes[" "] = {
	input = function()
		-- vi<Space>[ to select region without spaces, tabs, and \n
		local char = getchar()
		local ok, input = pcall(function()
			return BRACKETS[char].input
		end)
		if not ok or not input then
			return
		end
		local location = string.gsub(input[2], [[%(%)%.%*%(%)]], "[\n\t ]*().-()[\n\t ]*")
		return { input[1], location }
	end,
}

recipes["j"] = {
	input = japanize_bracket({
		["("] = { "（().-()）" },
		["{"] = { "｛().-()｝" },
		["["] = { "「().-()」" },
		["]"] = { "『().-()』" },
	}, {
		b = function(dict)
			local ret = {}
			for _, v in pairs(dict) do
				table.insert(ret, v)
			end
			return { ret }
		end,
	}),
	output = japanize_bracket({
		["("] = { left = "（", right = "）" },
		["{"] = { left = "｛", right = "｝" },
		["["] = { left = "「", right = "」" },
		["]"] = { left = "『", right = "』" },
	}, {}),
}

return {
	{ "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", lazy = true },
	{
		"https://github.com/echasnovski/mini.ai",
		event = "ModeChanged",
		config = function()
			--[[
      Examples:
        vi[ selects inside single bracket and vi] selects inside double brackets.
        (){}<> works similary

        vij[ selects inside 「」. 
        I intorduce some hacks because `custom_textobjects` does not support multiple characters as keys.
      ]]
			local gen_spec = require("mini.ai").gen_spec
			local custom_textobjects = {}
			for k, v in pairs(recipes) do
				custom_textobjects[k] = v.input
			end
			custom_textobjects.d = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })
			custom_textobjects.D = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })

			require("nvim-treesitter-textobjects")
			require("mini.ai").setup({
				n_lines = 100,
				mappings = {
					around = "a",
					inside = "i",
					around_next = "",
					inside_next = "",
					around_last = "",
					inside_last = "",
					goto_left = "g[",
					goto_right = "g]",
				},
				custom_textobjects = custom_textobjects,
			})
		end,
	},
	{
		"https://github.com/echasnovski/mini.surround",
		keys = {
			-- NOTE: <nop> cannot be a lazy load trigger
			-- https://github.com/folke/lazy.nvim/commit/3e4c795cec32481bc6d0b30c05125fdf7ef2d412
			{ "s", "<cmd><cr>", mode = "" },
		},
		config = function()
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
					add = "sa",
					delete = "sd",
					replace = "sr",
					find = "",
					find_left = "",
					highlight = "",
					update_n_lines = "",
					suffix_last = "",
					suffix_next = "",
				},
				custom_surroundings = vim.tbl_extend("force", recipes, {
					t = t,
				}),
			})
		end,
	},
}
