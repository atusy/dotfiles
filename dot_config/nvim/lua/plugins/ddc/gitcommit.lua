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
  local bufname = vim.api.nvim_buf_get_name(buf)
  local gitdir = vim.fs.dirname(bufname) or ""
  local gitroot = gitdir:match("/%.git$") and vim.fs.dirname(gitdir or "") or vim.fn.getcwd()
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

local function setting(buf, completion_items, semantic, scopes, logs)
  local curpos = vim.fn.getcurpos()
  local row, col = curpos[2] - 1, curpos[3]
  if row > 0 then
    vim.fn["pum#set_buffer_option"]({ max_height = vim.o.pumheight })
    return {}
  end

  local gitlog_source_option = {
    mark = "  log",
    minAutoCompleteLength = 0,
    sorters = {}, -- should be chronological order
    matchers = {}, -- manually matched in Lua
    converters = { "converter_fuzzy" },
    isVolatile = true,
  }

  local gitlog_source_param = { items = {} }
  local subject = vim.api.nvim_buf_get_text(0, row, 0, row, col, {})[1] or ""
  local re = vim.regex([[\k\+$]])
  for _, log in pairs(logs) do
    if vim.startswith(log, subject) then
      local i, j = re:match_str(subject)
      local cword = i and j and subject:sub(i, j + 1) or ""
      local delta = 0
      if subject ~= cword then
        delta = delta + 1
        if cword ~= "" then
          delta = delta + 1
        end
      end
      table.insert(gitlog_source_param.items, { word = log:sub(#subject - #cword + delta) })
    end
  end

  local space = subject:find("%s")
  if (space and space < col) or (semantic and subject:match(":")) then
    vim.fn["pum#set_buffer_option"]({ max_height = vim.o.pumheight })
    local sources = vim.fn["ddc#custom#get_global"]().sources
    table.insert(sources, 1, "gitlog")
    return {
      sources = sources,
      sourceOptions = { gitlog = gitlog_source_option },
      sourceParams = { gitlog = gitlog_source_param },
    }
  end

  vim.fn["pum#set_buffer_option"]({ max_height = #completion_items + 5 })

  return {
    sources = { "parametric", "gitlog" },
    backspaceCompletion = true,
    sourceOptions = {
      around = { mark = "", isVolatile = true, maxItems = 1 },
      parametric = {
        mark = "  commit-prefix",
        minAutoCompleteLength = 0,
        matchers = { "matcher_fuzzy" },
        converters = semantic and { "converter_fuzzy" } or { "converter_fuzzy", "converter_string_match" },
        sorters = { "sorter_fuzzy" },
        isVolatile = true,
      },
      gitlog = gitlog_source_option,
    },
    sourceParams = {
      parametric = { items = semantic and subject:match("%(") and scopes or completion_items },
      gitlog = gitlog_source_param,
    },
    filterParams = {
      converter_string_match = {
        regexp = [==[\p{RI}\p{RI}|\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?(\u{200D}\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?)+|\p{EPres}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})?|\p{Emoji}(\p{EMod}+|\u{FE0F}\u{20E3}?|[\u{E0020}-\u{E007E}]+\u{E007F})]==],
        flags = "ug",
      },
    },
  }
end

local function setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitcommit",
    callback = function(ctx)
      local completion_items = gather(read_template(ctx.buf), regex_emoji)
      local semantic = #completion_items == 0
      local scopes = {}
      local gitlog_stdout = vim.system({ "git", "log", "-n", "100", "--format=%s" }):wait().stdout or ""
      local logs = {}
      for word in string.gmatch(gitlog_stdout, "[^\n]+") do
        table.insert(logs, word)
      end
      vim.fn["ddc#custom#alias"]("source", "gitlog", "parametric")

      local added = {}
      if semantic then
        completion_items = {}
        local skip = {}
        for _, log in pairs(logs) do
          local prefix = string.match(log, "^%S+%(%S+%)!?:")
          if prefix and not added[prefix] then
            added[prefix] = true
            table.insert(completion_items, { word = prefix })
            local word = prefix:gsub(".*%(", ""):gsub("%).*", "")
            if not skip[word] then
              skip[word] = true
              table.insert(scopes, { word = word })
            end
          end
        end
        for _, word in pairs({ "feat", "prefix", "fix", "chore", "refactor", "style", "test", "release" }) do
          table.insert(completion_items, { word = word })
        end
      end

      vim.fn["ddc#custom#set_context_filetype"]("gitcommit", function()
        return setting(ctx.buf, completion_items, semantic, scopes, logs)
      end)
    end,
  })
end

return setup
