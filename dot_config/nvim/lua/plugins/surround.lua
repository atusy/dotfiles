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

        sjaiw[ surrounds inner word with 「」
        Unfortunately, sjr[] replaces 「」 with [[]], not 『』
      ]=]
      local lang = ''
      vim.api.nvim_create_autocmd('ModeChanged', {
        group = utils.augroup,
        pattern = '*:[ovV\x16]*',
        callback = function() lang = '' end
      })
      local function localize(rhs, language)
        return function()
          lang = language or ''
          return rhs
        end
      end

      set_keymap({ 'n', 'x' }, 'sj', localize('s', 'ja'), { remap = true, expr = true })

      local function multilingual(default, dict)
        return function()
          local ret = dict[lang] or default
          lang = ''
          return ret
        end
      end

      require('mini.surround').setup({
        n_lines = 100,
        mappings = {
          find = 'st',
          find_left = 'sT',
          highlight = 'sH',
        },
        custom_surroundings = {
          ['{'] = {
            input = multilingual(
              { '%b{}', '^.().*().$' },
              { ja = { '｛().-()｝' } }
            ),
            output = multilingual(
              { left = '{', right = '}' },
              { ja = { left = '｛', right = '｝' } }
            ),
          },
          ['}'] = {
            input = { '%b{}', '^.%{().*()%}.$' },
            output = { left = '{{', right = '}}' },
          },
          ['('] = {
            input = multilingual(
              { '%b()', '^.().*().$' },
              { ja = { '（().-()）' } }
            ),
            output = multilingual(
              { left = '(', right = ')' },
              { ja = { left = '（', right = '）' } }
            ),
          },
          [')'] = {
            input = { '%b()', '^.%(().*()%).$' },
            output = { left = '((', right = '))' },
          },
          ['['] = {
            input = multilingual(
              { '%b[]', '^.().*().$' },
              { ja = { '「().-()」' } }
            ),
            output = multilingual(
              { left = '[', right = ']' },
              { ja = { left = '「', right = '」' } }
            ),
          },
          [']'] = {
            input = multilingual(
              { '%b[]', '^.%[().*()%].$' },
              { ja = { '『().-()』' } }
            ),
            output = multilingual(
              { left = '[[', right = ']]' },
              { ja = { left = '『', right = '』' } }
            ),
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
