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

local function exec()
  -- init UI
  vim.api.nvim_exec2(
    [[
    GinDiff ++opener=tabnew --staged
    GinBuffer ++opener=topleft\ vs graph -n 20
    GinStatus ++opener=aboveleft\ sp
    aboveleft sp
    exe 'e ' .. tempname()
    ]],
    {}
  )
  local tab = vim.api.nvim_get_current_tabpage()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_set_option_value("filetype", "gitcommit", { buf = buf })

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

  -- commands and keymaps
  vim.api.nvim_buf_create_user_command(buf, "Apply", function()
    if commit(buf) == 0 then
      leave(tab, buf, augroup)
    end
  end, {})
  vim.api.nvim_buf_create_user_command(buf, "Cancel", function()
    leave(tab, buf, augroup)
  end, {})
  vim.keymap.set("n", "<C-S><C-Q>", "<Cmd>Apply<CR>", { buffer = buf })
end

return {
  exec = exec,
}
