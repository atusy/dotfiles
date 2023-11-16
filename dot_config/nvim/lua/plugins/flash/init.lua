return {
  {
    "https://github.com/folke/flash.nvim",
    lazy = true,
    init = function()
      --[[ f-motion ]]
      local motions = {
        f = { label = { after = false, before = { 0, 0 } }, jump = { autojump = true } },
        t = { label = { after = false, before = { 0, 1 } }, jump = { autojump = true, pos = "start" } },
        F = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { autojump = true, pos = "start", inclusive = false },
        },
        T = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { autojump = true, pos = "end", inclusive = false },
        },
      }

      for k, conf in pairs(motions) do
        local conv = k == "t"
            and function(x)
              return "." .. require("plugins.flash.query").kensaku(x)
            end
          or require("plugins.flash.query").kensaku
        local matcher = require("plugins.flash.matchers").char_matcher(conv, k == "f" or k == "t")
        vim.keymap.set({ "n", "x", "o" }, k, function()
          require("flash").jump(vim.tbl_extend("force", {
            labels = [[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#$%^&*()[]`'=-{}~"+_]],
            mode = "char",
            matcher = matcher,
            labeler = function() end,
            highlight = {
              matches = false,
              groups = { current = require("flash.config").get().highlight.groups.label },
            },
          }, conf))
        end)
      end

      --[[ incsearch ]]
      vim.keymap.set({ "n", "x", "o" }, ";", function()
        local cache = {}

        require("flash").jump({
          labels = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_]],
          label = { before = true, after = false },
          matcher = require("plugins.flash.matchers").incremental_matcher(nil, cache),
          labeler = function() end,
        })

        cache = {}
      end)

      --[[ search register ]]
      vim.keymap.set("n", "gn", function()
        require("flash").jump({
          labels = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_]],
          search = { multi_window = false, mode = "search" },
          label = { before = true, after = false },
          pattern = vim.fn.getreg("/"),
        })
      end)
    end,
    config = function()
      require("flash").setup({
        modes = {
          char = { enabled = false },
          search = { enabled = false },
          treesitter = { enabled = false },
        },
        highlight = { groups = { label = "DiagnosticError" } },
      })
    end,
  },
}
