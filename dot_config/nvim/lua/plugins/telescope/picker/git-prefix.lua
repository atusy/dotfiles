local M = {}

local function search_filelines(fname, pat)
  return vim.tbl_filter(function(x)
    return vim.regex(pat):match_str(x) ~= nil -- much faster than vim.fn.match
  end, vim.fn.readfile(fname))
end

M.regex_emoji = "["
  .. [[\U0001F600-\U0001F64F\U0001F300-\U0001F5FF\U0001F680-\U0001F6FF\U0001F1E0-\U0001F1FF\U00002500-\U00002BEF\U00002702-\U000027B0\U00002702-\U000027B0\U0001f926-\U0001f937\U00010000-\U0010ffff\u2640-\u2642\u2600-\u2B55\u200d\u23cf\u23e9\u231a\ufe0f\u3030]]
  .. "]"

function M.prefix_emoji(buf, sources)
  if true then
    -- currently testing ddc.git-prefix
    return
  end
  buf = buf or vim.api.nvim_get_current_buf()
  if not sources then
    local bufname = vim.api.nvim_buf_get_name(buf)
    if vim.endswith(bufname, ".git/COMMIT_EDITMSG") then
      sources = { vim.fs.dirname(vim.fs.dirname(bufname)) .. "/.gitmessage", ".gitmessage" }
    else
      sources = { ".gitmessage" }
    end
  end

  -- Search for candidates
  local emoji_lines = {}
  for _, fname in ipairs(sources) do
    if #emoji_lines ~= 0 then
      break
    end
    if vim.fn.filereadable(fname) == 1 then
      emoji_lines = search_filelines(fname, M.regex_emoji)
    end
  end
  if #emoji_lines == 0 then
    return
  end

  -- find emoji
  require("telescope.pickers")
    .new({}, {
      previewer = false,
      prompt_title = "Emoji Prefix",
      finder = require("telescope.finders").new_table({ results = emoji_lines }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, _)
        local action_state = require("telescope.actions.state")
        local actions = require("telescope.actions")
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          local emoji = vim.fn.matchstr(selection[1], M.regex_emoji)
          if emoji ~= "" then
            vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, { emoji })
          end
        end)
        return true
      end,
    })
    :find()
end

return M
