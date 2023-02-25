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

M.urlencode = M.create_visual_converter(function(url)
  return url:gsub("\n", "\r\n"):gsub("([^%w ])", M.char_to_hex):gsub(" ", "+")
end)

M.urldecode = M.create_visual_converter(function(url)
  return url:gsub("+", " "):gsub("%%(%x%x)", M.hex_to_char)
end)

function M.sample(x)
  local _x, y = { unpack(x) }, {}
  for _ = 1, #x do
    table.insert(y, table.remove(_x, math.random(#_x)))
  end
  return y
end

return M
