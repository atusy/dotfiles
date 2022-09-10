local vim = vim

local gintonic = {
  opt = {},
  tonic = {},
  gin = {},
  utils = {},
}

local merge_table = function(x, y)
  local ret = {}

  for k, v in pairs(y or {}) do
    ret[k] = v
  end

  for k, v in pairs(x or {}) do
    ret[k] = v
  end

  return ret
end

local function ginparams(params, cmd)
  local params_list = {}
  for k, v in pairs(merge_table(params, cmd and gintonic.opt.params[cmd])) do
    table.insert(params_list, "++" .. k .. "=" .. v:gsub(" ", [[\ ]]))
  end
  return table.concat(params_list, " ")
end

local function gincmd(cmd, params, args, merge)
  return vim.cmd(table.concat({
    cmd,
    ginparams(params, merge == true and cmd),
    args or ""
  }, " "))
end

gintonic.gin.ginbuffer = function(params, args, merge, bo)
  bo = merge_table(bo, {})
  local autocmd = vim.api.nvim_create_autocmd("FileType", {
    pattern = "gin",
    callback = function()
      for k, v in pairs(bo) do
        vim.api.nvim_buf_set_option(0, k, v)
      end
    end,
    once = true,
  })
  pcall(gincmd, "GinBuffer", params, args, merge == nil or merge)
  pcall(vim.api.nvim_del_autocmd, autocmd)
end

gintonic.tonic.show = function(obj, params, args)
  obj = gintonic.opt.get_object(obj)
  if obj == nil then
    return false
  end
  gintonic.gin.ginbuffer(params, "show " .. obj .. " " .. (args or ""))
  return true
end

gintonic.utils.is_object = function(s)
  return type(s) == "string" and s ~= "" and os.execute("git cat-file -e " .. s .. " 2>/dev/null") == 0
end

local create_object_getter = function(getter)
  return function()
    local w = getter()
    return gintonic.utils.is_object(w) and w or nil
  end
end

local function get_nth_word(s, n)
  s = s or vim.api.nvim_get_current_line()
  local i = 0
  for w in s:gmatch("%S+") do
    i = i + 1
    if i == n then
      return w
    end
  end
end

local function get_cursor_word(win)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(win or 0)[2] + 1
  local cur = line:sub(col, col)
  if cur == " " or cur == "" then return "" end
  local left = line:sub(1, col):gsub(".*%s", "")
  local right = line:sub(col + 1, -1):gsub("%s.*", "")
  return left .. right
end

gintonic.utils.object_getters = {
  gitrebase = create_object_getter(function() return get_nth_word(nil, 2) end),
  gintonicgraph = create_object_getter(function() return get_nth_word(nil, 2) end),
  default = function(x)
    if x ~= nil then
      return gintonic.utils.is_object(x) and x or nil
    end
    local get = gintonic.utils.object_getters[vim.api.nvim_buf_get_option(0, "filetype")]
    if get == nil then
      return create_object_getter(get_cursor_word)()
    end
    return get()
  end
}

local function _keymap_ginshow(opt)
  -- shortcuts
  local get = gintonic.opt.get_object or gintonic.utils.object_getters.default
  local show = gintonic.tonic.show
  local show_split = function(obj)
    return show(obj, {opener = "belowright split"})
  end

  -- git-show in preview window
  local win_preview = nil
  local function preview()
    local obj = get()

    -- invoke show() in preview window if possible
    if win_preview ~= nil and vim.api.nvim_win_is_valid(win_preview) then
      vim.api.nvim_win_call(win_preview, function() show(obj) end)
      return
    end

    -- invoke show() in new window, save window handler, and go back
    local win_cur = vim.api.nvim_get_current_win()
    local ok = show_split(obj)
    if ok then
      win_preview = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(win_cur)
    end
  end

  -- keymaps
  for _, v in ipairs({
    {"<Plug>(gintonic-show)", function() show() end},
    {"<Plug>(gintonic-show-split)", function() show_split() end},
    {"<Plug>(gintonic-preview)", function() preview() end},
  }) do
    vim.keymap.set("n", v[1], v[2], {buffer = 0})
  end

  if opt.keymap ~= false then
    for _, v in ipairs({
      {"gf", "<Plug>(gintonic-show)"},
      {"<C-W>f", "<Plug>(gintonic-show-split)"},
      {"<C-W><C-F>", "<Plug>(gintonic-show-split)"},
      {"<Down>", "j<Plug>(gintonic-preview)"},
      {"<Up>", "k<Plug>(gintonic-preview)"},
    }) do
      vim.keymap.set("n", v[1], v[2], {buffer = 0})
    end
  end
end

--[[ setup ]]
local function create_command()
  for nm, val in pairs({
    GintonicDiff = {
      function(params) gincmd("GinDiff", {}, params.args) end
    },
    GintonicGraph = {
      function(params)
        gintonic.gin.ginbuffer(
          {},
          "log --graph --oneline " .. params.args,
          true,
          {filetype = "gintonicgraph"}
        )
      end
    }
  }) do
    vim.api.nvim_create_user_command(nm, val[1], {force = true, nargs = "*"})
  end
end

local function create_autocmd(opt)
  opt = merge_table(opt, gintonic.opt)
  vim.api.nvim_create_augroup("gintonic-default", {})
  vim.api.nvim_create_autocmd("FileType", {
    pattern = {"gitrebase", "gintonicgraph"},
    callback = function(_) _keymap_ginshow(opt) end,
    group = "gintonic-default",
  })
end

local default = {
  keymap = function() return true end,
  params = function() return {} end,
  get_object = function() return gintonic.utils.object_getters.default end
}

gintonic.opt = {}
for k, f in pairs(default) do
  gintonic.opt[k] = f()
end

gintonic.setup = function(opt)
  opt = type(opt) == "table" and opt or {}
  gintonic.opt = {}
  for k, v in pairs(default) do
    gintonic.opt[k] = opt[k] == nil and v() or opt[k]
  end
  create_command()
  create_autocmd()
end

return gintonic
