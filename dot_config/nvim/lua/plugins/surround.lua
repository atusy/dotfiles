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

      set_keymap(
        'n', 's(', '<Plug>(operator-sandwich-add-query1st)<C-F>',
        { desc = 'sandwich query with () and start insert before (' }
      )
      set_keymap(
        'x', 's(', '<Plug>(operator-sandwich-add)<C-F>',
        { desc = 'sandwich query with () and start insert before (' }
      )
    end
  },
  {
    'echasnovski/mini.surround',
    keys = { { 's', mode = '' } },
    config = function()
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
        }
      })
    end,
  },
}
