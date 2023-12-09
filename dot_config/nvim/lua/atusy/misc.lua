local M = {}

function M.char_to_hex(c)
  return string.format("%%%02X", string.byte(c))
end

function M.hex_to_char(x)
  return string.char(tonumber(x, 16))
end

function M.create_visual_converter(callback)
  return function()
    local reg_z = vim.fn.getreginfo("z")
    vim.cmd('noautocmd normal! "zygv')
    local vtext = vim.fn.getreg("z")
    vim.fn.setreg("z", reg_z)

    local encoded = callback(vtext)
    vim.cmd("normal! c" .. encoded)
  end
end

M.urlencode = M.create_visual_converter(function(...)
  vim.uri_encode(...)
end)

M.urldecode = M.create_visual_converter(function(...)
  vim.uri_decode(...)
end)

function M.sample(x)
  local _x, y = { unpack(x) }, {}
  for _ = 1, #x do
    table.insert(y, table.remove(_x, math.random(#_x)))
  end
  return y
end

function M.jump_file(forward)
  local buf_cur = vim.api.nvim_get_current_buf()
  local jumplist = vim.fn.getjumplist()
  local jumps = jumplist[1]
  local idx_cur = jumplist[2] + 1
  local function is_target(buf)
    return buf ~= buf_cur and vim.api.nvim_buf_is_loaded(buf)
  end

  if forward then
    for i = 1, #jumps - idx_cur do
      if is_target(jumps[idx_cur + i].bufnr) then
        return i .. "<C-I>"
      end
    end
  else
    for i = 1, idx_cur - 1 do
      if is_target(jumps[idx_cur - i].bufnr) then
        return i .. "<C-O>"
      end
    end
  end
end

function M.move_floatwin(row, col)
  local conf = vim.api.nvim_win_get_config(0)
  if conf.relative == "" then
    return false
  end
  for k, v in pairs({ row = row, col = col }) do
    if type(conf[k]) == "table" then
      conf[k][false] = conf[k][false] + v
    else
      conf[k] = conf[k] + v
    end
  end
  vim.api.nvim_win_set_config(0, conf)
  return true
end

---@param path string
function M.in_cwd(path)
  return vim.startswith(path, vim.uv.cwd() .. "/") ---@diagnostic disable-line: undefined-field
end

---@param opts? { on_none: fun(str): nil }
function M.open_cfile(opts)
  opts = opts or {}
  local cfile = vim.fn.expand("<cfile>") --[[@as string]]

  -- Open URLs in browser
  if cfile:match("^https?://") then
    vim.ui.open(cfile)
    return
  end

  if not vim.uv.fs_stat(cfile) then ---@diagnostic disable-line: undefined-field
    if type(opts.on_none) == "function" then
      opts.on_none(cfile)
    end
    return
  end

  -- Open non-text in browser
  local needs_ui_open = {
    png = true,
    jpg = true,
  }
  local suffix, cnt = cfile:gsub(".*%.", "")
  if cnt == 1 and needs_ui_open[suffix:lower()] then
    vim.ui.open(cfile)
    return
  end

  -- Fallback to gF
  vim.cmd([[normal! gF]])
end

return M
