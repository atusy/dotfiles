local M = {}

---Create migemo-based vim-regex query
---@param pat string pattern to be converted to migemo
---@return string
function M.kensaku(pat)
  if pat:match("[0-9A-Z]") then
    return pat
  end
  local str = pat
  local query = ""
  for _ = 1, #str do
    local left, right = string.find(str, " +", 0, false)
    if left == nil then
      return query .. vim.fn["kensaku#query"](str)
    end
    if left > 1 then
      query = query .. vim.fn["kensaku#query"](string.sub(str, 1, left - 1))
    end
    query = query .. string.rep([[\(\s\|　\)]], right - left + 1)
    str = string.sub(str, right + 1)
  end
  return query
end

return M
