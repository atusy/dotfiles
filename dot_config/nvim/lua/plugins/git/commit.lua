local function leave(tab, buf, augroup)
  vim.schedule(function()
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    if not vim.api.nvim_tabpage_is_valid(tab) then
      return
    end
    if vim.api.nvim_get_current_tabpage() == tab then
      vim.cmd("tabclose")
    end
  end)
end

local function commit(buf)
  local res = vim
    .system({ "git", "commit", "--file", "-" }, {
      stdin = vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    })
    :wait()
  if res.code ~= 0 then
    vim.notify("Failed to commit:", vim.log.levels.ERROR)
  end
  if res.stdout and res.stdout:match("%w") then
    vim.notify(res.stdout)
  end
  if res.stderr and res.stderr:match("%w") then
    vim.notify(res.stderr, vim.log.levels.ERROR)
  end
  return res.code
end

local function get_message(ref)
  local res = vim.system({ "git", "log", "-n", "1", "--format=%s%n%n%b", ref }):wait()
  if res.code == 0 then
    local message = {}
    for line in res.stdout:gmatch("[^\n]*") do
      table.insert(message, line)
    end
    return message
  end
  vim.notify(res.stderr, vim.log.levels.ERROR)
end

local function exec()
  -- init UI
  vim.api.nvim_exec2(
    [[
    GinDiff ++opener=tabnew --staged
    GinBuffer ++opener=topleft\ vs graph -n 20
    set number
    GinStatus ++opener=aboveleft\ sp
    aboveleft sp
    exe 'e ' .. tempname()
    set filetype=gitcommit
    ]],
    {}
  )

  -- get ui data
  local tab = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()

  -- autocmds
  local augroup = vim.api.nvim_create_augroup(tostring(buf), {})
  vim.api.nvim_create_autocmd({ "TabClosed" }, {
    group = augroup,
    callback = function(ctx)
      if ctx.file == tostring(tab) then
        leave(tab, buf, augroup)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufHidden", "BufDelete" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      leave(tab, buf, augroup)
    end,
  })

  -- Ex-commands
  vim.api.nvim_buf_create_user_command(buf, "Apply", function()
    if commit(buf) == 0 then
      leave(tab, buf, augroup)
    end
  end, {})
  vim.api.nvim_buf_create_user_command(buf, "Cancel", function()
    leave(tab, buf, augroup)
  end, {})

  -- mappings
  vim.keymap.set("n", "<C-S><C-Q>", "<Cmd>Apply<CR>", { buffer = buf })
  local n = 0
  local function replace_message(delta)
    n = n + delta
    if n <= 0 then
      n = 0
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, n == 0 and {} or get_message("HEAD~" .. tostring(n)))
  end
  vim.keymap.set("n", "g<C-O>", function()
    replace_message(1)
  end)
  vim.keymap.set("n", "g<C-I>", function()
    replace_message(-1)
  end)
end

return {
  exec = exec,
}
