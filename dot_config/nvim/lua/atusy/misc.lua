local M = {}

function M.char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

function M.hex_to_char(x)
  return string.char(tonumber(x, 16))
end

function M.create_visual_converter(callback)
  return function()
    local reg_z = vim.fn.getreginfo('z')
    vim.cmd('noautocmd normal! "zygv')
    local vtext = vim.fn.getreg('z')
    vim.fn.setreg('z', reg_z)

    local encoded = callback(vtext)
    vim.cmd('normal! c' .. encoded)
  end
end

M.urlencode = M.create_visual_converter(function(url)
  return url:gsub("\n", "\r\n"):gsub("([^%w ])", M.char_to_hex):gsub(" ", "+")
end)

M.urldecode = M.create_visual_converter(function(url)
  return url:gsub("+", " "):gsub("%%(%x%x)", M.hex_to_char)
end)

function M.sample(x)
  local _x, y = { unpack(x) }, {}
  for _ = 1, #x do table.insert(y, table.remove(_x, math.random(#_x))) end
  return y
end

--[[ highlight markdown codeblock ]]
local function is_root_node(bufnr, node)
  if node:parent() ~= nil then return false end
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

local function set_extmark(bufnr, ns, range, hl_group)
  vim.api.nvim_buf_set_extmark(bufnr, ns, range[1], range[2], {
    end_row = range[3],
    end_col = range[4],
    hl_eol = true,
    priority = 1,
    hl_group = hl_group or '@illuminate'
  })
end

local function hl_child_codeblocks(bufnr, ns, node, start_row, end_row)
  for k, v in node:iter_children() do
    if k:type() == 'code_fence_content' then
      set_extmark(bufnr, ns, { k:range() })
    else
      local sr, _, er, _ = k:range()
      if (start_row <= sr and sr <= end_row) or (start_row <= er and er <= end_row) then
        hl_child_codeblocks(bufnr, ns, k, start_row, end_row)
      end
    end
  end
end

local function hl_next_codeblocks(bufnr, ns, node, start_row, end_row)
  local n = node
  while true do
    n = n:next_sibling()
    if n == nil then return end
    local row, _, _, _ = n:range()
    if row <= end_row then
      if n:type() == 'code_fence_content' then
        set_extmark(bufnr, ns, { n:range() })
      else
        hl_child_codeblocks(bufnr, ns, n, start_row, end_row)
      end
    end
  end
end

local function hl_codeblocks_in_range(bufnr, ns, node, start_row, end_row)
  local ancestors = list_parent_nodes(node)
  local process_children = true
  for i = #ancestors, 1, -1 do
    local n = ancestors[i]
    if n:type() == 'code_fence_content' then
      process_children = false
      set_extmark(bufnr, ns, { n:range(0) })
    end
    hl_next_codeblocks(bufnr, ns, n, start_row, end_row)
  end
end

local NAMESPACES_CODEBLOCKS = {
  [false] = vim.api.nvim_create_namespace('atusy-extmark-1'),
  [true] = vim.api.nvim_create_namespace('atusy-extmark-2')
}
local _current_ns_key = false

local function update_namespaces(bufnr, ns_key, start_row, end_row)
  start_row = start_row or vim.fn.getpos('w0')[2] - 1
  end_row = end_row or vim.fn.getpos('w$')[2] - 1
  local first_node = get_first_node_in_range(bufnr or 0, start_row, end_row)

  -- highlight
  if first_node ~= nil then
    hl_codeblocks_in_range(bufnr, NAMESPACES_CODEBLOCKS[ns_key], first_node, start_row, end_row)
  end

  -- clear previous highlight
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACES_CODEBLOCKS[not ns_key], 0, -1)
  return ns_key
end

function M.highlight_codeblock(ctx)
  local first_row = vim.fn.getpos('w0')[2] - 1
  local last_row = vim.fn.getpos('w$')[2] - 1
  update_namespaces(ctx.buf, _current_ns_key, first_row, last_row)

  local augroup = vim.api.nvim_create_augroup('hoge', {})
  vim.api.nvim_create_autocmd(
    {
      'TextChanged', 'TextChangedI', 'TextChangedP',
      -- 'WinScrolled'
    },
    {
      group = augroup,
      buffer = ctx.buf,
      callback = function()
        -- wait for parser update and avoid wrong highlights on o```<Esc>dd
        vim.schedule(function()
          first_row = vim.fn.getpos('w0')[2] - 1
          last_row = vim.fn.getpos('w$')[2] - 1
          _current_ns_key = update_namespaces(
            ctx.buf, not _current_ns_key, first_row, last_row
          )
        end)
      end,
    })
  vim.api.nvim_create_autocmd({ 'WinScrolled' }, {
    group = augroup,
    buffer = ctx.buf,
    callback = function()
      local prev_first, prev_last = first_row, last_row
      first_row = vim.fn.getpos('w0')[2] - 1
      last_row = vim.fn.getpos('w$')[2] - 1

      if (first_row > prev_last) or (last_row < prev_first) then
        _current_ns_key = update_namespaces(
          ctx.buf, not _current_ns_key, first_row, last_row
        )
        return
      end

      -- clear_namespaceする前に、first_rowからlast_rowまでのnamespaceを継承する必要あり
      local key = _current_ns_key
      if first_row < prev_first then
        key = update_namespaces(ctx.buf, _current_ns_key, first_row, prev_first - 1)
      end
      if last_row > prev_last then
        key = update_namespaces(ctx.buf, _current_ns_key, prev_last + 1, last_row)
      end
      _current_ns_key = key
    end,
  })
end

return M
