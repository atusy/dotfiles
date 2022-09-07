local vim = vim

M = {}

local function _ginbuffer(cmd, opt)
  opt = opt or {}
  local autocmd = vim.api.nvim_create_autocmd("FileType", {
    pattern = "gin",
    callback = function()
      for k, v in pairs(opt) do
        vim.api.nvim_buf_set_option(0, k, v)
      end
    end,
    once = true,
  })
  pcall(vim.cmd, "GinBuffer " .. cmd)
  pcall(vim.api.nvim_del_autocmd, autocmd)
end

local function _keymap_ginshow(sha_extractor, opt)
  -- git-show with split below
  local function show(line, opener)
    line = line or vim.api.nvim_get_current_line()
    opener = opener or [[++opener=belowright\ split]]
    local sha = sha_extractor ~= nil
      and sha_extractor(line)
      or line:gsub("^[^%s]+%s+", ""):gsub("%s+.*", "")
    if sha == "" or os.execute("git cat-file -e " .. sha .. " 2>/dev/null") ~= 0 then
      return false
    end
    _ginbuffer(
      (opt.processor and ("++processor=" .. opt.processor .. " ") or "")
      .. opener .. [[ show ]] .. sha
    )
    return true
  end

  -- git-show in preview window
  local win_preview = nil
  local function preview()
    local line = vim.api.nvim_get_current_line()

    -- invoke show() in preview window if possible
    if win_preview ~= nil and vim.api.nvim_win_is_valid(win_preview) then
      vim.api.nvim_win_call(win_preview, function() show(line, "") end)
      return
    end

    -- invoke show() in new window, save window handler, and go back
    local win_cur = vim.api.nvim_get_current_win()
    local ok = show(line)
    if ok then
      win_preview = vim.api.nvim_get_current_win()
      vim.api.nvim_set_current_win(win_cur)
    end
  end

  -- keymaps
  for _, v in ipairs({
    {"<Plug>(gintonic-show)", function() show() end},
    {"<Plug>(gintonic-preview)", function() preview() end},
  }) do
    vim.keymap.set("n", v[1], v[2], {buffer = 0})
  end

  if opt.keymap then
    for _, v in ipairs({
      {"K", "<Plug>(gintonic-show)"},
      {"<Down>", "j<Plug>(gintonic-preview)"},
      {"<Up>", "k<Plug>(gintonic-preview)"},
    }) do
      vim.keymap.set("n", v[1], v[2], {buffer = 0})
    end
  end
end

local function _create_command()
  for nm, val in pairs({
    GintonicDelta = {
      function(opt) vim.cmd([[GinDiff ++processor=delta ]] .. opt.args) end
    },
    GintonicGraph = {
      function(opt)
        _ginbuffer(
          "log --graph --oneline " .. opt.args,
          {filetype = "gintonicgraph"}
        )
      end
    }
  }) do
    vim.api.nvim_create_user_command(nm, val[1], {force = true, nargs = "*"})
  end
end

local function _create_autocmd(opt)
  vim.api.nvim_create_augroup("gintonic-default", {})
  vim.api.nvim_create_autocmd("FileType", {
    pattern = {"gitrebase", "gintonicgraph"},
    callback = function(_) _keymap_ginshow(nil, opt) end,
    group = "gintonic-default",
  })
end

M.default = {
  keymap = true,
  processor = nil
}

M.setup = function(opt)
  if type(opt) ~= "table" then
    opt = {}
  end
  for k, v in pairs(M.default) do
    if opt[k] == nil then
      opt[k] = v
    end
  end
  _create_command()
  _create_autocmd(opt)
end

return M
