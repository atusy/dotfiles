local utils = require("atusy.utils")
local set_keymap = utils.set_keymap

local function node_open_edit()
  local p = require("nvim-tree.api").tree.get_node_under_cursor().absolute_path
  local has_chowcho, chowcho = pcall(require, "chowcho")
  local nwins = #vim.api.nvim_tabpage_list_wins(0)
  if (nwins <= 2) or (vim.fn.isdirectory(p) == 1) or not has_chowcho then
    require("nvim-tree.api").node.open.edit()
    return
  end
  chowcho.run(function(w)
    vim.api.nvim_set_current_win(w)
    vim.cmd.edit(p)
  end, {
    exclude = function(buf, win)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      if ft == "NvimTree" then
        return true
      end

      local winconf = vim.api.nvim_win_get_config(win)
      if winconf.external or winconf.relative ~= "" or not winconf.focusable then
        return true
      end

      return false
    end,
  })
end

return {
  "nvim-tree/nvim-tree.lua",
  lazy = true,
  cond = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  init = function(p)
    if not p.cond then
      return
    end
    set_keymap("n", "S", function()
      require("nvim-tree.api").tree.focus()
    end)
  end,
  config = function()
    require("nvim-tree").setup({
      git = { ignore = false },
      renderer = { icons = { show = { git = false } } },
      remove_keymaps = true,
      on_attach = function(buffer)
        local api = require("nvim-tree.api")
        local default_text = "★ "
        local function nmap(lhs, rhs, desc, opts)
          local o = vim.tbl_extend("force", opts or {}, {
            desc = desc and (default_text .. " " .. desc) or nil,
            buffer = buffer,
          })
          vim.keymap.set("n", lhs, rhs, o)
        end

        vim.api.nvim_buf_set_var(buffer, "telescope_keymaps_default_text", default_text)

        -- Custom
        nmap("#", function()
          api.tree.find_file(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(vim.fn.win_getid(vim.fn.winnr("#")))))
        end, "reveal the buffer in the previous window")
        nmap("S", "<Cmd>NvimTreeClose<CR>")
        nmap("h", api.node.navigate.parent_close, "node: close the parent")
        nmap("l", api.node.open.no_window_picker, "node: open in the previous window")
        nmap("o", api.node.run.system, "node: run system")
        nmap("<CR>", node_open_edit, "node: open in a chosen window")
        nmap("!", api.tree.toggle_hidden_filter, "toggle hidden")
        nmap("<C-R>", "<Cmd>NvimTreeRefresh<CR>", "refresh")
        nmap("D", api.fs.trash, "fs: trash")
        nmap(" rn", api.fs.rename_sub, "fs: rename")
        nmap("M", api.marks.bulk.move, "mark: bulk move")
        nmap("p", api.fs.paste, "fs: paste")
        nmap("d", "<Nop>")
        nmap("dd", api.fs.cut, "fs: cut")
        nmap("y", "<Nop>")
        nmap("yy", api.fs.copy.node, "fs: copy")
        nmap("ya", api.fs.copy.absolute_path, "fs: clipboard absolute path")
        nmap("yr", api.fs.copy.relative_path, "fs: clipboard relative path")
        nmap("K", api.node.show_info_popup, "node: info")

        -- Defaults
        nmap("a", api.fs.create, "fs: add")
        nmap("x", api.fs.cut, "fs: cut")
        nmap("p", api.fs.paste, "fs: paste")
        nmap("<C-]>", api.tree.change_root_to_node, "tree: cd")
        nmap("<lt>", api.node.navigate.sibling.prev, "node: sibling prev")
        nmap(">", api.node.navigate.sibling.next, "node: sibling next")
        nmap("f", api.live_filter.start, "live filter: start")
        nmap("m", api.marks.toggle, "mark: toggle")
      end,
    })
  end,
}
