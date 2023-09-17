-- skkeleton
local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local function set_mapped_keys(exceptions)
  -- stylua: ignore
  local default = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "!", '"', "#", "$", "%", "&", "'", "(", ")", ",", ".", "/", ";", ":", "]", "@", "[", "-", "^", "\\", ">", "?", "_", "+", "*", "}", "`", "{", "=", "~", "<lt>", "<Bar>", "<BS>", "<C-h>", "<CR>", "<Space>", "<C-q>", "<PageUp>", "<PageDown>", "<C-j>", "<C-g>", "<Esc>" }
  local _exceptions = {}
  for _, v in pairs(exceptions) do
    _exceptions[v] = true
  end
  local maps = {}
  for _, m in pairs(default) do
    if _exceptions[m] ~= true then
      table.insert(maps, m)
    end
  end
  vim.g["skkeleton#mapped_keys"] = maps
end

return {
  {
    "vim-skk/skkeleton",
    dependencies = {
      { "vim-denops/denops.vim" },
    },
    config = function()
      set_keymap({ "i", "c" }, "<C-J>", "<Plug>(skkeleton-enable)")
      local register_kanatable = vim.fn["skkeleton#register_kanatable"]
      register_kanatable("rom", require("plugins.skkeleton.azik"))
      register_kanatable("rom", {
        ["\\"] = "disable",
        ["<s-l>"] = "zenkaku",
        ["'"] = "katakana",
        ["z "] = { "　", "" },
        ["z."] = { "……", "" },
        [";"] = { "っ", "" },
        [":"] = { "：", "" },
      })

      -- `:`で`っ`を送りがなとした変換を開始
      vim.fn["skkeleton#register_keymap"]("input", '"', "henkanPoint")

      vim.api.nvim_create_autocmd("User", {
        group = utils.augroup,
        pattern = "skkeleton-enable-post",
        callback = function(ctx)
          vim.keymap.set({ "i", "c" }, ":", function()
            -- NOTE: do not call skkeleton#handle directory. Instead, use expr mapping to handle keys in sync
            local state = vim.g["skkeleton#state"]
            local mode = vim.fn["skkeleton#mode"]()
            if mode ~= "abbrev" and state.phase == "input:okurinasi" then
              return [[<Cmd>call skkeleton#handle('handleKey', {'key': ['"', ";"]})<CR>]] -- 「っ」で変換開始
            end
            return [[<Cmd>call skkeleton#handle('handleKey', {'key': ':'})<CR>]]
          end, { buffer = true, expr = true })
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        group = utils.augroup,
        pattern = "skkeleton-disable-post",
        callback = function()
          pcall(vim.keymap.del, { "i", "c" }, ":", { buffer = true })
        end,
      })

      -- filetypeに応じた一部キーの無効化
      vim.api.nvim_create_autocmd("User", {
        group = utils.group,
        pattern = "skkeleton-enable-pre",
        callback = function(ctx)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = ctx.buf })
          local exceptions = {}
          if ft == "TelescopePrompt" then
            table.insert(exceptions, "<CR>")
          end
          set_mapped_keys(exceptions)
        end,
      })

      -- 辞書
      local lazyroot = require("lazy.core.config").options.root
      local function dict(nm, repo)
        return vim.fs.joinpath(lazyroot, repo or "dict", "SKK-JISYO." .. nm)
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
          dict("jawiki", "jawiki-kana-kanji-dict"),
        },
      })

      -- init
      vim.api.nvim_create_autocmd("InsertEnter", {
        group = utils.group,
        once = true,
        callback = "skkeleton#initialize",
      })
    end,
  },
  {
    "skk-dev/dict",
    lazy = true,
  },
  {
    "tokuhirom/jawiki-kana-kanji-dict",
    lazy = true,
  },
}
