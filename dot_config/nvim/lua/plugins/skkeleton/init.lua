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
    "https://github.com/vim-skk/skkeleton",
    dependencies = {
      { "https://github.com/vim-denops/denops.vim" },
    },
    build = function(p)
      require("plugins.denops.utils").cache_plugin(p, true)
    end,
    init = function(p)
      -- manually cache to enable input as soon as possible
      require("plugins.denops.utils").cache_plugin(p, false)
    end,
    config = function()
      vim.keymap.set({ "i", "c", "t" }, "<C-J>", "<Plug>(skkeleton-enable)")
      vim.keymap.set("n", "<C-J>", "i<Plug>(skkeleton-enable)")
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

      local augroup = vim.api.nvim_create_augroup("atusy.skkeleton", {})
      vim.api.nvim_create_autocmd("User", {
        group = augroup,
        pattern = "skkeleton-enable-post",
        callback = function(ctx)
          -- NOTE: do not call skkeleton#handle directory. Instead, use expr mapping to handle keys in sync
          local mode = vim.api.nvim_get_mode().mode
          vim.keymap.set(mode, ":", function()
            -- NOTE: seems like clean up is done by the time of skkeleton-disable-post
            local skk_state = vim.g["skkeleton#state"]
            local skk_mode = vim.fn["skkeleton#mode"]()
            if skk_mode ~= "abbrev" and skk_state.phase == "input:okurinasi" then
              return [[<Cmd>call skkeleton#handle('handleKey', {'key': ['"', ";"]})<CR>]] -- 「っ」で変換開始
            end
            return [[<Cmd>call skkeleton#handle('handleKey', {'key': ':'})<CR>]]
          end, { buffer = ctx.buf, expr = true })
        end,
      })

      -- filetypeに応じた一部キーの無効化
      vim.api.nvim_create_autocmd("User", {
        group = augroup,
        pattern = "skkeleton-enable-pre",
        callback = function(ctx)
          local ft = vim.bo[ctx.buf].filetype
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
        useGoogleJapaneseInput = true,
        markerHenkan = "",
        markerHenkanSelect = "",
        globalDictionaries = {
          dict("L"),
          dict("propernoun"),
          dict("geo"),
          dict("station"),
          dict("hukugougo"),
          dict("mazegaki"),
          dict("jinmei"),
          dict("fullname"),
          dict("edict2"),
          dict("assoc"),
          dict("jawiki", "jawiki-kana-kanji-dict"),
          dict("emoji"),
        },
      })

      -- init
      vim.fn["skkeleton#initialize"]()
    end,
  },
  { "https://github.com/skk-dev/dict", lazy = true },
  { "https://github.com/tokuhirom/jawiki-kana-kanji-dict", lazy = true },
}
