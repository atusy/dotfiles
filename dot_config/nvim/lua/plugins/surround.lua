local utils = require('utils')
local set_keymap = utils.set_keymap

return {
  {
    'machakann/vim-sandwich',
    cond = false,
    keys = { { 's', mode = '' }, },
    config = function()
      vim.g['sandwich#recipes'] = vim.deepcopy(vim.g['sandwich#default_recipes'])
      local recipes = vim.fn.deepcopy(vim.g['operator#sandwich#default_recipes'])
      table.insert(recipes, {
        buns = { '(', ')' },
        kind = { 'add' },
        action = { 'add' },
        cursor = 'head',
        command = { 'startinsert' },
        input = { vim.api.nvim_replace_termcodes("<C-F>", true, false, true) },
      })
      vim.g['operator#sandwich#recipes'] = recipes
    end
  },
  {
    'echasnovski/mini.surround',
    keys = { { 's', mode = '' } },
    config = function()
      --[=[
      Examples
        saiw[ surrounds inner word with [] and saiw] surrounds inner word with [[]]
        Similar behaviors occurs with (){}<>

        saiwj[ surrounds inner word with 「」
        srj[j] replaces 「」 with 『』
      ]=]
      require('mini.surround').setup({
        n_lines = 100,
        mappings = {
          find = 'st',
          find_left = 'sT',
          highlight = 'sH',
        },
        custom_surroundings = {
          ['{'] = {
            input = { '%b{}', '^.().*().$' },
            output = { left = '{', right = '}' },
          },
          ['}'] = {
            input = { '%b{}', '^.%{().*()%}.$' },
            output = { left = '{{', right = '}}' },
          },
          ['('] = {
            input = { '%b()', '^.().*().$' },
            output = { left = '(', right = ')' },
          },
          [')'] = {
            input = { '%b()', '^.%(().*()%).$' },
            output = { left = '((', right = '))' },
          },
          ['['] = {
            input = { '%b[]', '^.().*().$' },
            output = { left = '[', right = ']' },
          },
          [']'] = {
            input = { '%b[]', '^.%[().*()%].$' },
            output = { left = '[[', right = ']]' },
          },
          ['<'] = {
            input = { '%b<>', '^.().*().$' },
            output = { left = '<', right = '>' },
          },
          ['>'] = {
            input = { '%b[]', '^.<().*()>.$' },
            output = { left = '<<', right = '>>' },
          },
          ['j'] = {
            input = function()
              local ok, val = pcall(vim.fn.getchar)
              if not ok then return end
              local char = vim.fn.nr2char(val)

              local dict = {
                ['('] = { '（().-()）' },
                ['{'] = { '｛().-()｝' },
                ['['] = { '「().-()」' },
                [']'] = { '『().-()』' },
              }

              if char == 'b' then
                local ret = {}
                for _, v in pairs(dict) do
                  table.insert(ret, v)
                end
                return { ret }
              end

              if not dict[char] then error('%s is unsupported surroundings in Japanese') end

              return dict[char]
            end,
            output = function()
              local ok, val = pcall(vim.fn.getchar)
              if not ok then return end
              local char = vim.fn.nr2char(val)

              local dict = {
                ['('] = { left = '（', right = '）' },
                ['{'] = { left = '｛', right = '｝' },
                ['['] = { left = '「', right = '」' },
                [']'] = { left = '『', right = '』' },
              }

              if not dict[char] then error('%s is unsupported surroundings in Japanese') end

              return dict[char]
            end
          }
        }
      })
    end,
  },
}
