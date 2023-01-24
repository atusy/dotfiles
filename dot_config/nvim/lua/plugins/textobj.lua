local utils = require('utils')
local set_keymap = utils.set_keymap

return {
  {
    'echasnovski/mini.ai',
    event = 'ModeChanged',
    config = function()
      --[[
      -- TODO:
      -- Vi[ で [ と ] の間から両端の改行を抜いたところを選択したい
      local function template_bracket()
        local mode = vim.api.nvim_get_mode().mode
        local template = '^.%s().*()%s.$'
        if mode == 'V' then
          return string.format(
            template,
            '%s -\n?',
            '\n? -%s' -- '\n -%s' works, but this is not what I want...
          )
        end
        return template
      end

      local _bracket = template_bracket()

      -- mini.aiのtext objはnormalモードで評価されるので、条件分岐はModeChangedでやっておく
      vim.api.nvim_create_autocmd('ModeChanged', {
        pattern = '*:[vV]*',
        group = require('utils').augroup,
        callback = function()
          _bracket = template_bracket()
        end
      })

      local function bracket(x, left, right)
        return function()
          return {
            '%b' .. x,
            string.format(_bracket, left or '', right or ''),
          }
        end
      end

      -- usage:
      -- custom_textobjects = { ['{'] = bracket('{}'), ['}'] = bracket('{}', '%{', '%}') }
      ]]

      --[[
      Examples:
        vi[ selects inside single bracket and vi] selects inside double brackets.
        (){}<> works similary

        vij[ selects inside 「」. 
        I intorduce some hacks because `custom_textobjects` does not support multiple characters as keys.
      ]]
      require('mini.ai').setup({
        n_lines = 100,
        mappings = {
          around_next = 'a;',
          inside_next = 'i;',
          around_last = 'a,',
          inside_last = 'i,',
          goto_left = 'g(',
          goto_right = 'g)',
        },
        custom_textobjects = {
          ['{'] = { '%b{}', '^.().*().$' },
          ['}'] = { '%b{}', '^.%{().*()%}.$' },
          ['('] = { '%b()', '^.().*().$' },
          [')'] = { '%b()', '^.%(().*()%).$' },
          ['['] = { '%b[]', '^.().*().$' },
          [']'] = { '%b[]', '^.%[().*()%].$' },
          ['<'] = { '%b<>', '^.().*().$' },
          ['>'] = { '%b<>', '^.<().*()>.$' },
          ['j'] = function()
            local ok, val = pcall(vim.fn.getchar)
            if not ok then return end
            local char = vim.fn.nr2char(val)

            local dict = {
              ['('] = { '（().-()）' },
              ['{'] = { '｛().-()｝' },
              ['['] = { '「().-()」' },
              [']'] = { '『().-()』' },
            }

            if not dict[char] then error('%s is unsupported textobject in Japanese') end

            return dict[char]
          end
        }
      })
    end,
  },
}
