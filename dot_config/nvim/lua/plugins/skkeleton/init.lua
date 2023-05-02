-- skkeleton
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

return {
  {
    "vim-skk/skkeleton",
    config = function()
      set_keymap({ "i", "c" }, "<C-J>", "<Plug>(skkeleton-enable)")
      local register_kanatable = vim.fn["skkeleton#register_kanatable"]
      register_kanatable("rom", require("plugins.skkeleton.azik"))
      register_kanatable("rom", {
        ["\\"] = "disable",
        ["<s-l>"] = "zenkaku",
        ["'"] = "katakana",
        ["z "] = { "　", "" },
        [";"] = { "っ", "" },
        [":"] = { "っ", "" },
      })

      -- `:`で`っ`を送りがなとした変換を開始
      vim.fn["skkeleton#register_keymap"]("input", '"', "henkanPoint")

      vim.api.nvim_create_autocmd("User", {
        group = utils.augroup,
        pattern = "skkeleton-enable-post",
        callback = function()
          vim.keymap.set(
            "l",
            ":",
            [[<Cmd>call skkeleton#handle('handleKey', {'key': '"'})<CR>]]
              .. [[<Cmd>call skkeleton#handle('handleKey', {'key': ';'})<CR>]],
            { buffer = true }
          )
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = utils.augroup,
        pattern = "skkeleton-disable-post",
        callback = function()
          pcall(vim.keymap.del, "l", ":", { buffer = true })
        end,
      })
    end,
  },
}
