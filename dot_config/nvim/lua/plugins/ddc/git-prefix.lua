local regex_emoji = string.format(
  "[%s]",
  [[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF\U00002500-\U00002BEF\U00002702-\U000027B0\U00002702-\U000027B0\U0001f926-\U0001f937\U00010000-\U0010ffff\u2640-\u2642\u2600-\u2B55\u200d\u23cf\u23e9\u231a\ufe0f\u3030]]
)

local function gather(template, pat)
  local ok, regex = pcall(vim.regex, pat)

  if not ok or not regex then
    return {}
  end

  local ret = {}
  for _, line in pairs(template) do
    if regex:match_str(line) then
      table.insert(ret, { word = line })
    end
  end

  return ret
end

local function read_template(buf)
  local gitroot = vim.fs.dirname(vim.fs.dirname(vim.api.nvim_buf_get_name(buf)) or "")
  local template = vim.system({ "git", "config", "commit.template" }, { cwd = gitroot }):wait().stdout or ""
  template = template:gsub("\n", "")
  local configured = template ~= ""
  local abs = template:sub(0, 1) == "/"
  if not configured or abs then
    local local_template = vim.fs.joinpath(gitroot, ".gitmessage")
    local ok, lines = pcall(vim.fn.readfile, local_template)
    if ok then
      return lines
    end
  end
  if not configured then
    return {}
  end
  if not abs then
    template = vim.fs.joinpath(gitroot, template)
  end
  local ok, lines = pcall(vim.fn.readfile, template)
  return ok and lines or {}
end

local function setting(buf)
  local curpos = vim.fn.getcurpos()
  local row, col = curpos[2] - 1, curpos[3]
  if row > 0 then
    vim.fn["pum#set_option"]({ max_height = vim.o.pumheight })
    return {}
  end
  local text = vim.api.nvim_buf_get_text(0, row, 0, row, col, {})[1] or ""
  if text:match("%s") then
    vim.fn["pum#set_option"]({ max_height = vim.o.pumheight })
    return {}
  end

  local items = gather(read_template(buf), regex_emoji)

  local emoji = #items > 0

  if not emoji then
    items = {
      { word = "feat" },
      { word = "fix" },
      { word = "chore" },
      { word = "docs" },
      { word = "refactor" },
      { word = "style" },
      { word = "test" },
    }
  end

  vim.fn["pum#set_option"]({ max_height = #items })

  return {
    sources = { "parametric" },
    backspaceCompletion = true,
    sourceOptions = {
      parametric = {
        mark = "  commit-prefix",
        minAutoCompleteLength = 0,
        matchers = { "matcher_fuzzy" },
        converters = emoji and { "converter_fuzzy", "converter_string_match" } or { "converter_fuzzy" },
        sorters = { "sorter_fuzzy" },
        isVolatile = true,
      },
    },
    sourceParams = { parametric = { items = items } },
    filterParams = {
      converter_string_match = {
        regexp = [==[\p{RI}\p{RI}|\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?(\u{200D}\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?)+|\p{EPres}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?|\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})]==],
        flags = "ug",
      },
      -- converter_nth_word = { nth = 1 },
    },
  }
end

local function gitprefix()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function(ctx)
      vim.fn["ddc#custom#set_context_filetype"]("gitcommit", function()
        return setting(ctx.buf)
      end)
    end,
  })
end

return gitprefix
