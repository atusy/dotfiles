local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local function getchar()
  return vim.fn.nr2char(vim.fn.getchar())
end

local function japanize_bracket(dict, callbacks)
  return function()
    local char = getchar()

    if callbacks[char] then
      return callbacks[char](dict)
    end
    if dict[char] then
      return dict[char]
    end

    error("j" .. char .. " is unsupported")
  end
end

local BRACKETS = {
  ["{"] = {
    input = { "%b{}", "^.().*().$" },
    output = { left = "{", right = "}" },
  },
  ["}"] = {
    input = { "%b{}", "^.%{().*()%}.$" },
    output = { left = "{{", right = "}}" },
  },
  ["("] = {
    input = { "%b()", "^.().*().$" },
    output = { left = "(", right = ")" },
  },
  [")"] = {
    input = { "%b()", "^.%(().*()%).$" },
    output = { left = "((", right = "))" },
  },
  ["["] = {
    input = { "%b[]", "^.().*().$" },
    output = { left = "[", right = "]" },
  },
  ["]"] = {
    input = { "%b[]", "^.%[().*()%].$" },
    output = { left = "[[", right = "]]" },
  },
  ["<"] = {
    input = { "%b<>", "^.().*().$" },
    output = { left = "<", right = ">" },
  },
  [">"] = {
    input = { "%b[]", "^.<().*()>.$" },
    output = { left = "<<", right = ">>" },
  },
}

local recipes = vim.tbl_extend("force", {}, BRACKETS)

recipes[" "] = {
  input = function()
    -- vi<Space>[ to select region without spaces, tabs, and \n
    local char = getchar()
    local ok, input = pcall(function()
      return BRACKETS[char].input
    end)
    if not ok or not input then
      return
    end
    local location = string.gsub(input[2], [[%(%)%.%*%(%)]], "[\n\t ]*().-()[\n\t ]*")
    return { input[1], location }
  end,
}

recipes["j"] = {
  input = japanize_bracket({
    ["("] = { "（().-()）" },
    ["{"] = { "｛().-()｝" },
    ["["] = { "「().-()」" },
    ["]"] = { "『().-()』" },
  }, {
    b = function(dict)
      local ret = {}
      for _, v in pairs(dict) do
        table.insert(ret, v)
      end
      return { ret }
    end,
  }),
  output = japanize_bracket({
    ["("] = { left = "（", right = "）" },
    ["{"] = { left = "｛", right = "｝" },
    ["["] = { left = "「", right = "」" },
    ["]"] = { left = "『", right = "』" },
  }, {}),
}

return {
  {
    "echasnovski/mini.ai",
    event = "ModeChanged",
    config = function()
      --[[
      Examples:
        vi[ selects inside single bracket and vi] selects inside double brackets.
        (){}<> works similary

        vij[ selects inside 「」. 
        I intorduce some hacks because `custom_textobjects` does not support multiple characters as keys.
      ]]
      local gen_spec = require("mini.ai").gen_spec
      local custom_textobjects = {}
      for k, v in pairs(recipes) do
        custom_textobjects[k] = v.input
      end
      custom_textobjects.d = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })
      custom_textobjects.D = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })

      require("mini.ai").setup({
        n_lines = 100,
        mappings = {
          around_next = "a;",
          inside_next = "i;",
          around_last = "a,",
          inside_last = "i,",
          goto_left = "g(",
          goto_right = "g)",
        },
        custom_textobjects = custom_textobjects,
      })
    end,
  },
  {
    "echasnovski/mini.surround",
    keys = { { "s", "<Nop>", mode = "" } },
    config = function()
      --[=[
      Examples
        saiw[ surrounds inner word with [] and saiw] surrounds inner word with [[]]
        Similar behaviors occurs with (){}<>

        saiwj[ surrounds inner word with 「」
        srj[j] replaces 「」 with 『』
      ]=]
      require("mini.surround").setup({
        n_lines = 100,
        mappings = {
          find = "st",
          find_left = "sT",
          highlight = "sH",
        },
        custom_surroundings = recipes,
      })
    end,
  },
  {
    "machakann/vim-sandwich",
    cond = false,
    keys = { { "s", "<Nop>", mode = "" } },
    config = function()
      vim.g["sandwich#recipes"] = vim.deepcopy(vim.g["sandwich#default_recipes"])
    end,
  },
}
