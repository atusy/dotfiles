-- skkeleton
local set_keymap = require("atusy.utils").set_keymap

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
        [":"] = { ":", "" },
      })
    end,
  },
}
