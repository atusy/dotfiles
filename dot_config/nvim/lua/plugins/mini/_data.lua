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

local RECIPES_BRACKETS = {
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

local recipes = vim.tbl_extend("force", {}, RECIPES_BRACKETS)

recipes[" "] = {
	input = function()
		-- vi<Space>[ to select region without spaces, tabs, and \n
		local char = getchar()
		local ok, input = pcall(function()
			return RECIPES_BRACKETS[char].input
		end)
		if not ok or not input then
			return
		end
		local location = string.gsub(input[2], [[%(%)%.%*%(%)]], "[\n\t ]*().-()[\n\t ]*")
		return { input[1], location }
	end,
}

local japanese_brackets = {
	["("] = { left = "（", right = "）" },
	["{"] = { left = "｛", right = "｝" },
	["["] = { left = "「", right = "」" },
	["]"] = { left = "『", right = "』" },
	["<"] = { left = "〈", right = "〉" },
	[">"] = { left = "《", right = "》" },
}

recipes["j"] = {
	input = japanize_bracket(
		(function()
			local dict = {}
			for k, v in pairs(japanese_brackets) do
				dict[k] = { v.left .. "().-()" .. v.right }
			end
			return dict
		end)(),
		{
			b = function(dict)
				local ret = {}
				for _, v in pairs(dict) do
					table.insert(ret, v)
				end
				return { ret }
			end,
		}
	),
	output = japanize_bracket(japanese_brackets, {}),
}

return {
	japanese_brackets = japanese_brackets,
	surround_recipes = recipes,
}
