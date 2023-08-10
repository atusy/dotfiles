vim.filetype.add({
  filename = {
    [".envrc"] = "sh",
    [".profile"] = "sh",
    [".tf"] = "terraform",
  },
  pattern = {
    ["${HOME}/.local/share/chezmoi/.*"] = {
      function(path, bufnr)
        local filename, cnt = path:gsub("/dot_", "/.")
        if cnt == 0 then
          return
        end
        return vim.filetype.match({ filename = filename, buf = bufnr })
      end,
      { priority = -math.huge },
    },
    ["Dockerfile[._].*"] = { "dockerfile", { priority = -math.huge } },
  },
})
