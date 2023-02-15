return {
  "atusy/telescomp",
  dir = "/home/atusy/ghq/github.com/atusy/telescomp.nvim",
  event = "CmdlineEnter",
  config = function()
    local utils = require("atusy.utils")
    local cmdline_builtin = utils.require("telescomp.cmdline.builtin")
    vim.keymap.set("c", "<C-X><C-B>", cmdline_builtin.git_branches)
    vim.keymap.set("c", "<C-X><C-F>", cmdline_builtin.find_files)
    vim.keymap.set("c", "<C-X><C-M>", cmdline_builtin.builtin)
    vim.keymap.set("c", "<C-D>", "<C-L><Cmd>lua require('telescomp.cmdline.builtin').cmdline()<CR>")
    vim.keymap.set("n", "<Plug>(telescomp-colon)", ":", { remap = true })
    vim.keymap.set("n", "<Plug>(telescomp-slash)", "/", { remap = true })
    vim.keymap.set("n", "<Plug>(telescomp-question)", "?", { remap = true })
  end,
}
