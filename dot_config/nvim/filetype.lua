vim.filetype.add({
  filename = {
    ['.envrc'] = 'sh',
    ['.profile'] = 'sh',
    ['.tf'] = 'terraform',
  },
  pattern = {
    ['dot_.*'] = function(path, bufnr)
      return vim.filetype.match({
        filename = vim.fs.basename(path):gsub('^dot_', '.'),
        buf = bufnr,
      })
    end,
    ['Dockerfile[._].*'] = { 'dockerfile', { priority = -math.huge } }
  }
})
