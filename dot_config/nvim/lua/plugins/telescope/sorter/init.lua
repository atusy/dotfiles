local M = {}

function M.filter_only_sorter(sorter)
	sorter = sorter or require("telescope.config").values.generic_sorter()
	local base_scorer = sorter.scoring_function
	local score_match = require("telescope.sorters").empty().scoring_function()
	sorter.scoring_function = function(self, prompt, line)
		local score = base_scorer(self, prompt, line)
		if score <= 0 then
			return -1
		else
			return score_match
		end
	end
	return sorter
end

function M.filname_sorter(sorter)
	sorter = sorter or require("telescope.config").values.generic_sorter()
	local base_scorer = sorter.scoring_function
	sorter.scoring_function = function(self, prompt, _, entry, ...)
		return base_scorer(self, prompt, entry.filename, entry, ...)
	end
	return sorter
end

function M.regex_sorter(opts)
	sorter = sorter or require("telescope.config").values.generic_sorter()
	local score_match = require("telescope.sorters").empty().scoring_function()
	local target = function(_, line)
		return line
	end
	if type(opts.target) == "function" then
		target = opts.target
	elseif type(opts.target) == "string" then
		target = function(entry, _)
			return entry[opts.target]
		end
	end
	sorter.scoring_function = function(_, prompt, line, entry, ...)
		if vim.regex(prompt):match_str(target(entry, line)) then
			return score_match
		else
			return -1
		end
	end
	return sorter
end

return M
