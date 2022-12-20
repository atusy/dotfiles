local M = {}
function M.has_lsp_client(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for _, _ in pairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
    return true
  end
  return false
end

function M.attach_lsp(filetype)
  filetype = filetype or vim.api.nvim_buf_get_option(0, "filetype")
  local clients = {}
  for _, cl in ipairs(vim.lsp.get_active_clients()) do
    if cl.config and cl.config.filetypes then
      for _, ft in ipairs(cl.config.filetypes) do
        if ft == filetype then
          vim.lsp.buf_attach_client(0, cl.id)
          table.insert(clients, cl)
        end
      end
    end
  end
  return clients
end

return M
