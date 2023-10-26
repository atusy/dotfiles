local M = {}

function M.foldtext()
  local res = vim.treesitter.foldtext()

  if type(res) == "string" then
    return res
  end

  if (#res == 1 and res[1][1] == "{") or (#res == 2 and res[1][1]:match("^%s+$") and res[2][1] == "{") then
    local foldstart = vim.v.foldstart
    vim.v.foldstart = foldstart + 1
    local text = vim.treesitter.foldtext()
    if type(text) == "table" then
      for i, v in pairs(text) do
        if i == 1 and v[1]:match("^%s+$") then
          v[1] = " "
        end
        table.insert(res, v)
      end
    end
    vim.v.foldstart = foldstart
  end
  return res
end

return M
