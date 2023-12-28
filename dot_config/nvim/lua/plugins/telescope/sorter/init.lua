local M = {}

function M.filter_only_sorter(sorter)
	sorter = sorter or require("telescope.config").values.file_sorter()
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

return M
