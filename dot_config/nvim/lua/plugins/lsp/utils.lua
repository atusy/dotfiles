local M = {}

function M.attach_lsp(bufnr, filetype)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  filetype = filetype or vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  local clients = {}
  for _, cl in ipairs(vim.lsp.ge_clients()) do
    if not cl.attached_buffers[bufnr] then
      if cl.config and cl.config.filetypes then
        for _, ft in ipairs(cl.config.filetypes) do
          if ft == filetype then
            vim.lsp.buf_attach_client(bufnr, cl.id)
            table.insert(clients, cl)
          end
        end
      end
    end
  end
  return clients
end

return M
