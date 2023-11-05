local M = {}

function M.toggle_severity(handlers, severities)
  local config = vim.diagnostic.config()
  for _, handler_name in pairs(handlers) do
    local handler = config[handler_name]
    if handler == false then
      vim.diagnostic.config({ virtual_text = severities or true })
    end

    local target = {}
    for _, k in ipairs(vim.diagnostic.severity) do
      target[k] = handler == true
    end
    if type(handler) == "table" then
      for _, v in pairs(handler.severity) do
        target[vim.diagnostic.severity[v]] = true
      end
    end
    for _, k in pairs(severities) do
      target[k] = not target[k]
    end

    if handler == true then
      config[handler_name] = { severity = {} }
    else
      config[handler_name].severity = {}
    end
    for k, v in pairs(target) do
      if v then
        table.insert(config[handler_name].severity, vim.diagnostic.severity[k])
      end
    end
  end
  vim.diagnostic.config(config)
  return vim.diagnostic.config()
end

function M.underlined_severities()
  local config = vim.diagnostic.config().underline
  if type(config) == "boolean" then
    return config and vim.diagnostic.severity or {}
  end
  return config.severity
end

function M.goto_next_underline(opts)
  vim.diagnostic.goto_next(vim.tbl_extend("force", opts or {}, {
    severity = M.underlined_severities(),
  }))
end

function M.goto_prev_underline(opts)
  vim.diagnostic.goto_prev(vim.tbl_extend("force", opts or {}, {
    severity = M.underlined_severities(),
  }))
end

return M
