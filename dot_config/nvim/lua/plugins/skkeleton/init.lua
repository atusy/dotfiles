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

      local dictdir = vim.fs.joinpath(vim.fs.dirname(p.dir), "dict")
      vim.fn["skkeleton#config"]({
        globalDictionaries = {
          vim.fs.joinpath(dictdir, "SKK-JISYO.L"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.assoc"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.emoji"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.edict"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.edict2"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.fullname"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.geo"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.hukugougo"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.mazegaki"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.propernoun"),
          vim.fs.joinpath(dictdir, "SKK-JISYO.station"),
        },
      })
    end,
  },
  {
    "skk-dev/dict",
    cond = false,
  },
}
