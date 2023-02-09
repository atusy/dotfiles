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
function M.highlight_codeblock(ctx)
  local parser = vim.treesitter.get_parser(ctx.buf)
  local root = parser:parse()[1]:root()
  local prev = false
  local names = {
    [false] = vim.api.nvim_create_namespace('atusy-extmark-1'),
    [true] = vim.api.nvim_create_namespace('atusy-extmark-2')
  }

  local function set_extmark(bufnr, ns, range)
    vim.api.nvim_buf_set_extmark(bufnr, ns, range[1], range[2], {
      end_row = range[3],
      end_col = range[4],
      hl_eol = true,

      priority = 1,
      hl_group = '@illuminate'
    })
  end

  local function hi_children(bufnr, ns, node, start_row, end_row)
    for k, v in node:iter_children() do
      if k:type() == 'code_fence_content' then
        -- print(k:range())
        set_extmark(bufnr, ns, { k:range() })
      else
        local sr, _, er, _ = k:range()
        if (start_row <= sr and sr <= end_row) or (start_row <= er and er <= end_row) then
          hi_children(bufnr, ns, k, start_row, end_row)
        end
      end
    end
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

  local function hi_nexts(bufnr, ns, node, start_row, end_row)
    local n = node
    while true do
      n = n:next_sibling()
      if n == nil then return end
      local row, _, _, _ = n:range()
      if row <= end_row then
        if n:type() == 'code_fence_content' then
          set_extmark(bufnr, ns, { n:range() })
        else
          hi_children(bufnr, ns, n, start_row, end_row)
        end
      end
    end
  end

  local function hi2(bufnr, ns, node, start_row, end_row)
    local ancestors = list_parent_nodes(node)
    local process_children = true
    for i = #ancestors, 1, -1 do
      local n = ancestors[i]
      if n:type() == 'code_fence_content' then
        process_children = false
        set_extmark(bufnr, ns, { n:range(0) })
      end
      hi_nexts(bufnr, ns, n, start_row, end_row)
    end
  end

  local function is_root(bufnr, node)
    if node:parent() ~= nil then return false end
    local start_row, start_col, end_row, end_col = node:range()
    if start_row == 0 and start_col == 0 and end_col == 0 then
      return end_row == vim.api.nvim_buf_line_count(bufnr)
    end
    return false
  end

  local function get_first_node_in_range(bufnr, start_row, end_row)
    local node
    for row = start_row, end_row do
      node = vim.treesitter.get_node_at_pos(bufnr, row, 0, {})
      if not is_root(bufnr, node) then
        return node
      end
    end
  end

  local function hi_visible(bufnr)
    local ns = names[not prev]
    local start_row = vim.fn.getpos('w0')[2] - 1
    local end_row = vim.fn.getpos('w$')[2] - 1
    local first_node = get_first_node_in_range(bufnr or 0, start_row, end_row)
    -- highlight
    if first_node ~= nil then
      hi2(bufnr, ns, first_node, start_row, end_row)
    end

    -- clear previous highlight
    vim.api.nvim_buf_clear_namespace(bufnr or 0, names[prev], 0, -1)

    -- update prev
    prev = not prev
  end

  hi_visible(ctx.buf)

  local augroup = vim.api.nvim_create_augroup('hoge', {})
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'TextChangedP', 'WinScrolled' }, {
    group = augroup,
    buffer = ctx.buf,
    callback = function() hi_visible(ctx.buf) end,
  })
  -- TODO: WinScrolledで差分のみ扱いたい
end

return M
