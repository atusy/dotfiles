---@param node? TSNode
---@param _type string
---@return TSNode?
local function find_child(node, _type)
  if node then
    for n in node:iter_children() do
      if n:type() == _type then
        return n
      end
    end
  end
end

---@param patch TSNode
---@param line TSNode
---@return string?
local function unifieddiff_filename(patch, line)
  local line_deleted = line:type() == "line_deleted"
  local header = find_child(find_child(patch, "git_header"), "git_diff_header")
  if not header then
    return
  end
  local filename_node
  for n in header:iter_children() do
    if n:type() == "filename" then
      filename_node = n
      if line_deleted then
        break
      end
    end
  end
  local r0, c0, r1, c1 = filename_node:range()
  local filename = string.gsub(vim.api.nvim_buf_get_text(0, r0, c0, r1, c1, {})[1] or "", "^b/", "")
  if filename == "" or not vim.uv.fs_stat(filename) then
    return
  end
  return filename
end

---@param hunk TSNode
---@param line TSNode
---@return integer?
local function unifieddiff_row(hunk, line)
  local row = 0
  local line_type = line:type() == "line_deleted" and "line_deleted" or "line_added"
  local line_id = line:id()
  for n in hunk:iter_children() do
    local t = n:type()
    if t == "hunk_info" then
      local hunk_location = find_child(find_child(n, "hunk_range_new"), "hunk_location")
      if not hunk_location then
        return
      end
      local r0, c0, r1, c1 = hunk_location:range()
      local num = tonumber(vim.api.nvim_buf_get_text(0, r0, c0, r1, c1, {})[1])
      if not num then
        return
      end
      row = num
    end
    if n:id() == line_id then
      return row
    end
    if t == "line_nochange" or t == line_type then
      row = row + 1
    end
  end
end

local function unifieddiff_location()
  -- body
  local body = vim.treesitter.get_node()
  if not body or body:type() ~= "body" then
    return
  end

  -- line
  local line = body:parent()
  local line_type = line and line:type()
  if not line or not ({ line_added = true, line_deleted = true, line_nochange = true })[line_type] then
    return
  end

  -- hunk
  local hunk = line:parent()
  if not hunk or hunk:type() ~= "hunk" then
    return
  end

  -- patch
  local patch = hunk:parent()
  if not patch or patch:type() ~= "patch" then
    return
  end

  return {
    filename = unifieddiff_filename(patch, line),
    pos = { unifieddiff_row(hunk, line), vim.api.nvim_win_get_cursor(0)[2] - 1 },
    type = line_type,
  }
end

---@param filename string
---@return number
local function get_buf(filename)
  local buf = vim.fn.bufadd(filename)
  if vim.fn.bufloaded(buf) ~= 1 then
    vim.fn.bufload(buf)
  end
  return buf
end

--- open or focus the hover
---@param opts? { bufnr: integer, pos: {[1]: integer, [2]: integer}, relative?: string, providers?: string[] }
local function hover(opts)
  if vim.b.hover_preview then
    vim.api.nvim_set_current_win(vim.b.hover_preview)
  else
    require("hover").hover(type(opts) == "function" and opts() or opts)
  end
end

--- hover for diff
local function hover_diff()
  local loc = unifieddiff_location()
  if not loc or loc.type == "line_changed" then
    return
  end
  hover({ bufnr = get_buf(loc.filename), pos = loc.pos })
end

return {
  {
    "https://github.com/lewis6991/hover.nvim/",
    lazy = true,
    init = function()
      vim.keymap.set("n", "K", hover)
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ctx)
          if ({ diff = true, ["gin-diff"] = true })[ctx.match] then
            vim.keymap.set("n", "K", hover_diff, { buffer = ctx.buf })
          end
        end,
      })
    end,
    config = function()
      require("hover").setup({
        init = function()
          -- Require providers
          require("hover.providers.lsp")
          -- require('hover.providers.gh')
          -- require('hover.providers.gh_user')
          -- require('hover.providers.jira')
          -- require('hover.providers.man')
          -- require('hover.providers.dictionary')
        end,
        preview_opts = {
          border = "single",
        },
        preview_window = false,
        title = false,
        mouse_providers = {
          "LSP",
        },
        mouse_delay = 1000,
      })
    end,
  },
}
