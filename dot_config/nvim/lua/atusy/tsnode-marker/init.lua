---@alias Tsnode userdata
---@class Opts_automark
---@field is_target fun(x: userdata): boolean
---@field hl_group string
---@field linewise? boolean
---@field priority? number
---@class Opts: Opts_automark
---@field namespace number
---@field start_row number
---@field end_row number

local M = {}

local function is_root_node(bufnr, node)
  if node:parent() ~= nil then
    return false
  end
  local start_row, start_col, end_row, end_col = node:range()
  if start_row == 0 and start_col == 0 and end_col == 0 then
    return end_row == vim.api.nvim_buf_line_count(bufnr)
  end
  return false
end

local function list_parent_nodes(node)
  local list = {}
  local parent = node
  while parent ~= nil do
    table.insert(list, parent)
    parent = parent:parent()
  end
  return list
end

local function get_first_node_in_range(bufnr, start_row, end_row)
  local node
  for row = start_row, end_row do
    node = vim.treesitter.get_node_at_pos(bufnr, row, 0, {})
    if node and not is_root_node(bufnr, node) then
      return node
    end
  end
end

---@param buf number
---@param range number[]
---@param opts Opts
local function set_extmark(buf, range, opts)
  if opts.linewise ~= false then
    range = { range[1], 0, range[3] + (range[4] == 0 and 0 or 1), 0 }
  end

  vim.api.nvim_buf_set_extmark(buf, opts.namespace, range[1], range[2], {
    end_row = range[3],
    end_col = range[4],
    hl_eol = true,
    priority = opts.priority or 1,
    hl_group = opts.hl_group,
  })
end

---@param buf number
---@param node Tsnode
---@param opts Opts
local function mark_children(buf, node, opts)
  for k in node:iter_children() do
    if opts.is_target(k) then
      set_extmark(buf, { k:range() }, opts)
    else
      local sr, _, er, _ = k:range()
      if (opts.start_row <= sr and sr <= opts.end_row) or (opts.start_row <= er and er <= opts.end_row) then
        mark_children(buf, k, opts)
      end
    end
  end
end

---@param buf number
---@param node Tsnode
---@param opts Opts
local function mark_next_sibling(buf, node, opts)
  local n = node
  while true do
    n = n:next_sibling()
    if n == nil then
      return
    end
    local range = { n:range() }
    if range[1] <= opts.end_row then
      if opts.is_target(n) then
        set_extmark(buf, range, opts)
      else
        mark_children(buf, n, opts)
      end
    end
  end
end

---@param buf number
---@param opts Opts
function M.mark_range(buf, opts)
  local first_node = get_first_node_in_range(buf, opts.start_row, opts.end_row)

  if first_node == nil then
    return
  end

  local ancestors = list_parent_nodes(first_node)
  for i = #ancestors, 1, -1 do
    local n = ancestors[i]
    if opts.is_target(n) then
      set_extmark(buf, { n:range() }, opts)
    elseif i == 1 then
      mark_children(buf, n, opts)
    end
    mark_next_sibling(buf, n, opts)
  end
end

local NAMESPACES = {
  [false] = vim.api.nvim_create_namespace("atusy-extmark-1"),
  [true] = vim.api.nvim_create_namespace("atusy-extmark-2"),
}
local _current_ns_key = false

---@param buf number
---@param ns_key boolean
---@param start_row number
---@param end_row number
---@param opts Opts_automark
local function update_namespaces(buf, ns_key, start_row, end_row, opts)
  M.mark_range(buf, {
    is_target = opts.is_target,
    hl_group = opts.hl_group,
    linewise = opts.linewise,
    namespace = NAMESPACES[ns_key],
    start_row = start_row,
    end_row = end_row,
  })
  vim.api.nvim_buf_clear_namespace(buf, NAMESPACES[not ns_key], 0, -1)
  return ns_key
end

---@param buf number
---@param opts Opts_automark
function M.automark(buf, opts)
  local first_row = vim.fn.getpos("w0")[2] - 1
  local last_row = vim.fn.getpos("w$")[2] - 1
  update_namespaces(buf, _current_ns_key, first_row, last_row, opts)

  local augroup = vim.api.nvim_create_augroup("tsnode-marker-" .. tostring(buf), {})

  vim.api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
  }, {
    group = augroup,
    buffer = buf,
    callback = function()
      -- wait for parser update and avoid wrong highlights on o```<Esc>dd
      vim.schedule(function()
        first_row = vim.fn.getpos("w0")[2] - 1
        last_row = vim.fn.getpos("w$")[2] - 1
        _current_ns_key = update_namespaces(buf, not _current_ns_key, first_row, last_row, opts)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "WinScrolled" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      local prev_first, prev_last = first_row, last_row
      first_row = vim.fn.getpos("w0")[2] - 1
      last_row = vim.fn.getpos("w$")[2] - 1

      -- on pagewise scroll
      if (first_row > prev_last) or (last_row < prev_first) then
        _current_ns_key = update_namespaces(buf, not _current_ns_key, first_row, last_row, opts)
        return
      end

      -- on linewise scroll up or resize
      if first_row < prev_first then
        update_namespaces(buf, _current_ns_key, first_row, prev_first - 1, opts)
      end

      -- on linewise scroll down or resize
      if last_row > prev_last then
        update_namespaces(buf, _current_ns_key, prev_last + 1, last_row, opts)
      end
    end,
  })
end

return M
