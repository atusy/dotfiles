-- skkeleton
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

return {
  {
    "vim-skk/skkeleton",
    dependencies = {
      { "vim-denops/denops.vim" },
    },
    config = function(p)
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

      local lazyroot = require("lazy.core.config").options.root
      local function dict(nm)
        vim.fs.joinpath(lazyroot, "dict", "SKK-JISYO." .. nm)
      end
      vim.fn["skkeleton#config"]({
        globalDictionaries = {
          dict("L"),
          dict("assoc"),
          dict("emoji"),
          dict("edict"),
          dict("edict2"),
          dict("fullname"),
          dict("geo"),
          dict("hukugougo"),
          dict("mazegaki"),
          dict("propernoun"),
          dict("station"),
        },
      })
    end,
  },
  {
    "skk-dev/dict",
    cond = false,
  },
}
