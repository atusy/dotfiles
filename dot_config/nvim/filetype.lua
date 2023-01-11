vim.filetype.add({
  filename = {
    ['.envrc'] = 'sh',
    ['.profile'] = 'sh',
    ['.tf'] = 'terraform',
  },
  pattern = {
    ['${HOME}/.local/share/chezmoi/.*'] = {
      function(path, bufnr)
        if not path:match('/dot_') then return end
        return vim.filetype.match({
          filename = path:gsub('/dot_', '/.'),
          buf = bufnr,
        })
      end,
      {
        priority = -math.huge,
      }
    },
    ['Dockerfile[._].*'] = { 'dockerfile', { priority = -math.huge } }
  }
})
