local M = {}

M.background_groups = {
  "Comment",
  "Conditional",
  "Constant",
  "CursorLine",
  "CursorLineNr",
  "EndOfBuffer",
  "Function",
  "Identifier",
  "LineNr",
  "NonText",
  "Normal",
  "NormalNC",
  "Operator",
  "PreProc",
  "Repeat",
  "SignColumn",
  "Special",
  "Statement",
  "StatusLine",
  "StatusLineNC",
  "String",
  "Structure",
  "Todo",
  "Type",
  "Underlined",
}

---@type table<number, table<string, table<string, string>>>
M.modified_namespaces = {}
M.win_separator = { link = "Comment" }

---@param nsid number?
---@param groups string[]?
function M.remove_background(nsid, groups)
  nsid = nsid or 0
  groups = groups or M.background_groups
  M.modified_namespaces[nsid] = M.modified_namespaces[nsid] or {}

  for _, group in pairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, nsid, { name = group })
    if ok and (hl.background or hl.bg or hl.ctermbg) then
      vim.api.nvim_set_hl(nsid, group, vim.tbl_extend("force", hl, { bg = "NONE", ctermbg = "NONE" }))
      M.modified_namespaces[nsid][group] = hl
    end
  end

  local ok, hl = pcall(vim.api.nvim_get_hl, nsid, { group = "WinSeparator" })
  if ok then
    M.modified_namespace[nsid]["WinSeparator"] = hl
  end
  vim.api.nvim_set_hl(nsid, "WinSeparator", M.win_separator)
end

---@param nsid number?
function M.restore_background(nsid)
  nsid = nsid or 0
  local data = M.modified_namespaces[nsid]
  if not data then
    error("unmodified namespace id: " .. nsid)
  end
  for group, hl in pairs(data) do
    vim.api.nvim_set_hl(nsid, group, hl)
  end
  M.modified_namespaces[nsid] = nil
end

M.transparent = vim.env.NVIM_TRANSPARENT == "1"

function M.change_background(transparent)
  -- set state
  if transparent == nil then
    M.transparent = not M.transparent
  else
    M.transparent = transparent
  end

  -- change background
  if M.transparent then
    M.remove_background(0, M.background_groups)

    -- support for folke/styler.nvim
    for ns, id in pairs(vim.api.nvim_get_namespaces()) do
      if string.match(ns, "^styler__") then
        M.remove_background(id, M.background_groups)
      end
    end
  else
    for nsid, _ in pairs(M.modified_namespaces) do
      M.restore_background(nsid)
    end
  end

  -- mark colorschme be unmodified
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("atusy.highlight", {}),
    callback = function()
      M.modified_namespaces[0] = nil
      if M.transparent then
        M.change_background(M.transparent)
      end
    end,
  })

  -- redraw background for sure
  vim.schedule(function()
    vim.cmd("redraw!")
  end)
end

return M
