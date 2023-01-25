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

            if char == 'b' then
              local ret = {}
              for _, v in pairs(dict) do table.insert(ret, v) end
              return { ret }
            end

            if dict[char] then return dict[char] end

            error(char .. ' is unsupported textobjects in Japanese')
          end
        }
      })
    end,
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
                for _, v in pairs(dict) do table.insert(ret, v) end
                return { ret }
              end

              if dict[char] then return dict[char] end

              error(char .. ' is unsupported surroundings in Japanese')
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

              if dict[char] then return dict[char] end

              error(char .. ' is unsupported surroundings in Japanese')
            end
          }
        }
      })
    end,
  },
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
}
