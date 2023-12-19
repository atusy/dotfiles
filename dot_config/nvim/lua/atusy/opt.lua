local M = {
  ---@type boolean | {[1]: boolean; [string]: boolean} | nil nil is considered as true and [1] is for filetypes other than [string]
  format_on_save = true,
}

return M
