local M = {}

---Modified after https://github.com/neovim/neovim/blob/7f9fc2fbf03e18c1e4033763be4905707d7a84e7/runtime/lua/vim/treesitter/_fold.lua?plain=1#L402-L491
---under Apache License Version 2.0, January 2004 https://www.apache.org/licenses/
---@return { [1]: string, [2]: string[] }[]|string
function M.foldtext()
  local foldstart = vim.v.foldstart
  local bufnr = vim.api.nvim_get_current_buf()

  ---@type boolean, LanguageTree
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok then
    return vim.fn.foldtext()
  end

  local query = vim.treesitter.query.get(parser:lang(), "highlights")
  if not query then
    return vim.fn.foldtext()
  end

  local tree = parser:parse({ foldstart - 1, foldstart })[1]

  local line = vim.api.nvim_buf_get_lines(bufnr, foldstart - 1, foldstart, false)[1]
  if not line then
    return vim.fn.foldtext()
  end

  ---@type { [1]: string, [2]: string[], range: { [1]: integer, [2]: integer } }[] | { [1]: string, [2]: string[] }[]
  local result = {}

  local line_pos = 0

  for id, node, metadata in query:iter_captures(tree:root(), 0, foldstart - 1, foldstart) do
    local name = query.captures[id]
    local start_row, start_col, end_row, end_col = node:range()

    local priority = tonumber(metadata.priority or vim.highlight.priorities.treesitter)

    if start_row == foldstart - 1 and end_row == foldstart - 1 then
      -- check for characters ignored by treesitter
      if start_col > line_pos then
        table.insert(result, {
          line:sub(line_pos + 1, start_col),
          {},
          range = { line_pos, start_col },
        })
      end
      line_pos = end_col

      local text = line:sub(start_col + 1, end_col)
      table.insert(result, { text, { { "@" .. name, priority } }, range = { start_col, end_col } })
    end
  end

  local i = 1
  while i <= #result do
    -- find first capture that is not in current range and apply highlights on the way
    local j = i + 1
    while j <= #result and result[j].range[1] >= result[i].range[1] and result[j].range[2] <= result[i].range[2] do
      for k, v in ipairs(result[i][2]) do
        if not vim.tbl_contains(result[j][2], v) then
          table.insert(result[j][2], k, v)
        end
      end
      j = j + 1
    end

    -- remove the parent capture if it is split into children
    if j > i + 1 then
      table.remove(result, i)
    else
      -- highlights need to be sorted by priority, on equal prio, the deeper nested capture (earlier
      -- in list) should be considered higher prio
      if #result[i][2] > 1 then
        table.sort(result[i][2], function(a, b)
          return a[2] < b[2]
        end)
      end

      result[i][2] = vim.tbl_map(function(tbl)
        return tbl[1]
      end, result[i][2])
      result[i] = { result[i][1], result[i][2] }

      i = i + 1
    end
  end

  return result
end

return M
