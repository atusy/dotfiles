local function retry_on_buf_write_post(buf)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    buffer = buf,
    once = true,

    callback = function()
      require("conform").format({ bufnr = buf, async = true, lsp_fallback = true }, function(err)
        if err == nil then
          vim.cmd.up()
        elseif err:match("No formatters found for buffer") then
          return
        elseif err == "No result returned from LSP formatter" then
          return
        else
          vim.notify(err, vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

return {
  {
    "https://github.com/stevearc/conform.nvim",
    lazy = true,
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- format with gq{motion}
      vim.keymap.set("n", "gqq", function()
        -- for original gqq, use gqgq
        require("conform").format({ async = true, lsp_fallback = true })
      end)
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        group = augroup,
        callback = function(args)
          require("conform").format(
            { bufnr = args.buf, async = false, lsp_fallback = true, timeout_ms = 200 },
            function(err)
              if err == nil then
                return
              elseif err == "No result returned from LSP formatter" then
                return
              elseif err:match("No formatters found for buffer") then
                return
              elseif err:match("Formatter '.-' timeout") then
                retry_on_buf_write_post(args.buf)
              else
                vim.notify(err, vim.log.levels.ERROR)
              end
            end
          )
        end,
      })
    end,
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "ruff_format" }, -- black and isort are toooooo slow!
          javascript = { { "prettierd", "prettier" } },
          go = { "goimports", { "gofumpt", "gofmt" } },
        },
      })
    end,
  },
}
