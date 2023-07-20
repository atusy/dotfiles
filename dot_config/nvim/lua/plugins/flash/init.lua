local function kensaku_query(pat)
  local str = pat
  local query = ""
  for _ = 1, #str do
    local left, right = string.find(str, " +", 0, false)
    if left == nil then
      return query .. vim.fn["kensaku#query"](str)
    end
    if left > 1 then
      query = query .. vim.fn["kensaku#query"](string.sub(str, 1, left - 1))
    end
    query = query .. string.rep([[\(\s\|　\)]], right - left + 1)
    str = string.sub(str, right + 1)
  end
  return query
end

local function search_lines(lines, pat, col1, col2, row)
  row = row or 0
  col1 = col1 or 0
  col2 = col2 or 0
  local match_str = pat
  if type(pat) == "string" then
    local re = vim.regex(pat)
    match_str = function(...)
      return re:match_str(...)
    end
  end

  local n = #lines
  local matches = {}
  for i, line in pairs(lines) do
    local s = line
    local col = 0
    if i == n and col2 > 0 then
      s = s:sub(0, col2 - 1)
    end
    if i == 1 then
      col = col1
      s = s:sub(col1 + 1)
    end
    while s ~= "" do
      local first, last = match_str(s)
      if not first then
        break
      end
      table.insert(matches, {
        pos = { row + i, first + col },
        end_pos = { row + i, last + col - 1 },
      })
      s = s:sub(first + 1)
      local idx = vim.fn.byteidx(s, 1)
      s = s:sub(idx + 1)
      col = col + first + idx
    end
  end
  return matches
end

local function search(buf, pat, start, _end, strict_indexing)
  start = start or { 0, 0 }
  _end = _end or { -1, 0 }
  local end_ = _end[1] + ((_end[1] > 0 and _end[2] > 0) and 1 or 0)
  local lines = vim.api.nvim_buf_get_lines(buf, start[1], end_, strict_indexing or true)
  return search_lines(lines, pat, start[2], _end[2], start[1]), lines
end

local function key(m)
  return "w" .. m.win .. "r" .. m.pos[1] .. "c" .. m.pos[2]
end

local function sort(tbl, win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  table.sort(tbl, function(a, b)
    local ap, bp = a.pos, b.pos
    if ap[1] == bp[1] then
      return ap[2] < bp[2]
    end
    local dya = cursor[1] - ap[1]
    local dyb = cursor[1] - bp[1]
    return dya * dya < dyb * dyb
  end)
  return tbl
end

local function conv_default(str)
  return [[\c]] .. kensaku_query(str)
end

local function matcher(conv, cache)
  local curwin = vim.api.nvim_get_current_win()
  local labels
  conv = conv or conv_default
  if cache then
    cache.labels = {}
    labels = {}
  end
  return function(win, state)
    local wininfo = vim.fn.getwininfo(win)
    if win ~= curwin or state.pattern.pattern == "" or not wininfo or #wininfo == 0 then
      return {}
    end
    local buf, top, bot = wininfo[1].bufnr, wininfo[1].topline - 1, wininfo[1].botline
    local matches, lines = search(buf, conv(state.pattern.pattern), { top, 0 }, { bot, 0 })
    local test = setmetatable({}, {
      __index = function(self, k)
        self[k] = not vim.regex(conv(state.pattern.pattern .. k)):match_str(lines)
        return self[k]
      end,
    })
    local used = {}
    for _, m in pairs(matches) do
      m.win = win
      local lab = labels[key(m)]
      if lab then
        if test[lab] then
          m.label = lab
          used[lab] = true
        else
          labels[key(m)] = nil
        end
      end
    end

    if win == curwin then
      matches = sort(matches, win)
    end

    -- 大文字以外はmigemoと干渉しないように扱う
    local i = 1
    for lab in string.gmatch(state.opts.labels, ".") do
      if not matches[i] then
        return matches
      end
      if not used[lab] and (string.match(lab, "[ABCDEFGHIJKLMNOPQRSTUVWXYZ]") or test[lab]) then
        if not matches[i].label then
          matches[i].label = lab
          if labels then
            labels[key(matches[i])] = lab
          end
        end
        i = i + 1
      end
    end
    return matches
  end
end

return {
  {
    "folke/flash.nvim",
    lazy = true,
    dir = "~/ghq/github.com/folke/flash.nvim",
    init = function(p)
      local motions = {
        f = { label = { after = false, before = { 0, 0 } } },
        t = { label = { after = false, before = { 0, 1 } }, jump = { pos = "start" } },
        F = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { pos = "start", inclusive = false },
        },
        T = {
          label = { after = false, before = { 0, 0 } },
          search = { forward = false },
          jump = { pos = "end", inclusive = false },
        },
      }

      for _, motion in ipairs({ "f", "t", "F", "T" }) do
        vim.keymap.set({ "n", "x", "o" }, motion, function()
          local Config = require("flash.config")
          require("flash").jump(Config.get({
            mode = "char",
            jump = { autojump = true },
            search = {
              multi_window = false,
              mode = function(str)
                local pos = vim.api.nvim_win_get_cursor(0)
                return string.format("\\%%%dl%s%s", pos[1], motion == "t" and "." or "", kensaku_query(str))
              end,
              max_length = 1,
            },
            highlight = { matches = false },
          }, motions[motion]))
        end)
      end
      vim.keymap.set({ "n", "x", "o" }, ";", function()
        local cache = {}

        require("flash").jump({
          labels = [[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890!@#$%^&*()[]`'=-{}~"+_ ]],
          label = { before = true, after = false },
          matcher = matcher(cache),
          labeler = function() end,
        })

        cache = {}
      end)
    end,
    config = function()
      require("flash").setup({
        modes = {
          char = { enabled = false },
          search = { enabled = false },
          treesitter = { enabled = false },
        },
      })
    end,
  },
}
