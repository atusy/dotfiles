return {
  {
    "folke/flash.nvim",
    lazy = true,
    dir = "~/ghq/github.com/folke/flash.nvim",
    init = function(p)
      local leader = ""
      local Config = require("flash.config")
      local motions = {
        f = { label = { after = false, before = { 0, 0 } } },
        t = { label = { after = false, before = { 0, 1 } }, jump = { pos = "start" } },
        F = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { pos = "start", inclusive = false },
        },
        T = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { pos = "end", inclusive = false },
        },
      }

      for _, motion in ipairs({ "f", "t", "F", "T" }) do
        vim.keymap.set({ "n", "x", "o" }, leader .. motion, function()
          require("flash").jump(Config.get({
            mode = "char",
            jump = {
              autojump = true,
            },
            search = {
              multi_window = false,
              mode = function(str)
                -- do migemo search on the current line
                local pos = vim.api.nvim_win_get_cursor(0)
                local prefix = ("\\%%%dl"):format(pos[1])
                local pattern = vim.fn["kensaku#query"](str)
                if pattern == [[\m]] then
                  pattern = str
                end
                if motion == "t" then
                  pattern = "." .. pattern
                end
                return prefix .. pattern
              end,
              max_length = 1,
            },
            highlight = {
              matches = false,
            },
          }, motions[motion]))
        end)
      end
      vim.keymap.set({ "n", "x", "o" }, leader .. ";", function()
        local curwin = vim.api.nvim_get_current_win()
        require("flash").jump({
          labels = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
          label = { before = { 0, 0 }, after = false },
          matcher = function(win, state)
            if win ~= curwin then
              return {}
            end
            local matches = require("leap-search.engine").search(state.pattern.pattern, {
              engines = {
                { name = "string.find", plain = true, ignorecase = true },
                { name = "kensaku.query" },
              },
            }, { target_windows = { win } })
            local ret = {}
            for _, m in pairs(matches) do
              table.insert(ret, {
                win = m.wininfo.winid,
                pos = { m.pos[1], m.pos[2] - 1 },
                end_pos = { m.pos[3], m.pos[4] - 2 },
              })
            end
            return ret
          end,
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
      })
    end,
  },
}
