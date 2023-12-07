local augroup = vim.api.nvim_create_augroup("atusy.conform", {})

local function format_on_buf_write_post(buf, once)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    buffer = buf,
    once = once,
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

local function format_on_buf_write_pre(buf, once)
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    buffer = buf,
    once = once,
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
            format_on_buf_write_post(args.buf, true) -- as retry
          else
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      )
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
      format_on_buf_write_pre()
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
