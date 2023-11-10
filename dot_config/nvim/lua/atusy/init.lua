--[[ TODO
https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
https://github.com/sumneko/lua-language-server/wiki/Annotations
https://qiita.com/delphinus/items/fb905e452b2de72f1a0f
https://zenn.dev/nnsnico/articles/customize-lsp-handler
https://dev.classmethod.jp/articles/eetann-change-neovim-lsp-diagnostics-format/

## Plugin

"rlch/github-notifications.nvim",
use { 'LeafCage/vimhelpgenerator' }
use { 'mattn/emmet-vim',
use { 'pwntester/octo.nvim',
use { 'shinespark/vim-list2tree' }
use { 'skanehira/denops-docker.vim' }
use { 'skanehira/denops-graphql.vim',
use { 'skanehira/denops-silicon.vim',
use { 'skanehira/denops-translate.vim',
use { 'thinca/vim-quickrun',
use { 'thinca/vim-themis' }
use { 'tyru/open-browser-github.vim' }
use { 'windwp/nvim-autopairs',

https://github.com/monaqa/dial.nvim
https://github.com/anuvyklack/hydra.nvim
https://github.com/tani/glance-vim
https://github.com/folke/trouble.nvim
https://github.com/folke/which-key.nvim
https://github.com/rcarriga/nvim-notify
https://github.com/folke/noice.nvim
https://github.com/folke/todo-comments.nvim
https://github.com/simrat39/symbols-outline.nvim
https://github.com/kylechui/nvim-surround
https://github.com/edluffy/hologram.nvim
https://github.com/delphinus/ddc-treesitter
https://github.com/Afourcat/treesitter-terraform-doc.nvim
https://github.com/nullchilly/fsread.nvim
https://github.com/joechrisellis/lsp-format-modifications.nvim

https://github.com/monaqa/tree-sitter-unifieddiff
https://github.com/thinca/modesearch.vim
https://github.com/thinca/vim-partedit
https://github.com/uga-rosa/ccc.nvim
https://github.com/matsui54/ddc-buffer
https://github.com/David-Kunz/markid
https://github.com/stevearc/dressing.nvim
https://github.com/hrsh7th/nvim-gtd
https://github.com/hrsh7th/vim-searchx
https://github.com/b0o/SchemaStore.nvim
https://github.com/gaoDean/autolist.nvim
https://github.com/Exafunction/codeium.vim
]]

-- [[ helpers ]]
local set_keymap = vim.keymap.set
local utils = require("atusy.utils").require("atusy.utils") -- force reloading self
utils.setup()

--[[ options ]]
vim.opt.exrc = true
vim.opt.updatetime = 250

-- statuscolumn
vim.opt.signcolumn = "yes"

-- window
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.breakindent = true
vim.opt.fillchars = "eob: "
vim.opt.virtualedit = "block"

-- buffer
vim.opt.autoread = true
vim.opt.matchtime = 1
vim.opt.matchpairs:append(
  [[<:>,「:」,（:）,『:』,【:】,《:》,〈:〉,｛:｝,［:］,【:】,‘:’,“:”]]
)
vim.opt.mouse = "a"
vim.opt.pumheight = 10
vim.opt.pumblend = 25
vim.opt.winblend = 25
vim.opt.pumheight = 10
vim.opt.showmode = false
vim.opt.termguicolors = true
vim.opt.list = true
vim.opt.listchars = {
  tab = "▸▹┊",
  trail = "▫",
  extends = "»",
  precedes = "«",
}
vim.opt.cursorline = true
vim.opt.guicursor = {
  [[n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50]],
  [[a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor]],
  [[sm:block-blinkwait175-blinkoff150-blinkon175]],
}
vim.opt.foldtext = [[v:lua.require("atusy.fold").foldtext()]]

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.showmatch = true
vim.opt.incsearch = true

-- tab and indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- others
if vim.fn.executable("zsh") == 1 then
  vim.opt.shell = "zsh"
end
if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = [[rg --glob "!.git" --no-heading --vimgrep --follow $*]]
  vim.opt.grepformat = vim.opt.grepformat ^ { "%f:%l:%c:%m" }
end

--[[ commands ]]
vim.api.nvim_create_user_command("W", "write !sudo tee % >/dev/null", {})
vim.api.nvim_create_user_command("Normal", function(opts)
  local code = vim.api.nvim_replace_termcodes(opts.args, true, true, true)
  local normal = opts.bang and "normal!" or "normal"
  for i = opts.line1, opts.line2 do
    vim.cmd(i .. normal .. " " .. code)
  end
end, { nargs = 1, range = true, bang = true })

--[[ mappings ]]
vim.g.mapleader = " "
set_keymap({ "n", "x" }, "s", "<Nop>") -- be prefix for sandwich and fuzzy finders
set_keymap("n", "<C-G>", "2<C-G><Plug>(C-G)", { noremap = true })
set_keymap("n", "<Plug>(C-G)<C-G>", '<Cmd>let @+ = expand("%:~:.")<CR>')
set_keymap("n", "<Plug>(C-G)g", '<Cmd>let @+ = expand("%:~")<CR>')
set_keymap("x", "<C-G>", "<Plug>(C-G)", { noremap = true })
set_keymap("x", "<Plug>(C-G)<C-G>", "<C-G>", { noremap = true })
set_keymap("c", "<C-A>", "<Home>")
set_keymap("t", "<C-W>", [[<C-\><C-N><C-W>]])
set_keymap({ "", "!", "t" }, [[<C-\>]], [[<C-\><C-N>]], { nowait = true })
set_keymap("x", "p", "P")
set_keymap("x", "P", "p")
set_keymap("x", "zf", [[mode() == 'V' ? 'zf' : 'Vzf']], { expr = true })
set_keymap("x", "g/", "<Esc>/\\%V", { silent = true }) -- search within selection
set_keymap("x", " ue", [[<Cmd>lua require("atusy.misc").urlencode()<CR>]])
set_keymap("x", " ud", [[<Cmd>lua require("atusy.misc").urldecode()<CR>]])
set_keymap("n", "gf", "gF")

-- mappings: diagnostics
set_keymap("n", "[d", [[<Cmd>lua require("atusy.diagnostic").goto_prev_underline()<CR>]])
set_keymap("n", "]d", [[<Cmd>lua require("atusy.diagnostic").goto_next_underline()<CR>]])
set_keymap("n", "<Leader>q", [[<Cmd>lua vim.diagnostic.setloclist()<CR>]])
set_keymap("n", "<Leader>e", [[<Cmd>lua vim.diagnostic.open_float()<CR>]])

-- mappings: don't start a new undo block on horizontal moves on insert mode
set_keymap("i", "<Left>", "<C-G>U<Left>")
set_keymap("i", "<Right>", "<C-G>U<Right>")

-- mappings: register
set_keymap({ "n", "x" }, "x", '"_x')
set_keymap({ "n", "x" }, "X", '"_X')
set_keymap({ "n", "x" }, "gy", '"+y')
set_keymap({ "n", "x" }, "gY", '"+Y')

-- mappings: textobj
set_keymap({ "o", "x" }, "ii", "2i") -- e.g., vii' to select 'foo' including quotes but outer spaces
set_keymap({ "o", "x" }, "il", ":<c-u>keepjumps normal! g_v^<cr>", { silent = true })
set_keymap({ "o", "x" }, "al", ":<c-u>keepjumps normal! $v0<cr>", { silent = true })
set_keymap({ "o", "x" }, "ae", ":<c-u>keepjumps normal! G$vgo<cr>", { silent = true })

-- mappings: mouse
-- <2-LeftMouse> is for tyru/open-browser
set_keymap("!", "<LeftMouse>", "<Esc><LeftMouse>")
set_keymap("n", "<LeftDrag>", "<Nop>")
set_keymap("n", "<LeftRelease>", "<Nop>")

-- mappings: jumplist
set_keymap("n", "g<C-O>", function()
  return require("atusy.misc").jump_file(false)
end, { expr = true })
set_keymap("n", "g<C-I>", function()
  return require("atusy.misc").jump_file(true)
end, { expr = true })

-- mappings: save and ...
set_keymap({ "n", "x" }, "<Plug>(save)", function()
  vim.cmd((vim.fn.filereadable("%") == 0 and "up" or "write") .. " | redraw")
end)
set_keymap({ "i", "n" }, "<C-S>", [[<C-\><C-N><Plug>(save)<Plug>(C-S)]], { desc = "save" })
set_keymap("n", "<Plug>(C-S)<C-A>", "<cmd>wa<cr>", { desc = "save all" })
set_keymap("n", "<Plug>(C-S)<C-Q>", "<cmd>q<cr>", { desc = "save and quit" })
set_keymap("n", "<Plug>(C-S)<C-M>", function()
  local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  local bufext = bufname:gsub(".*%.", "")
  if bufext ~= "vim" and bufext ~= "lua" then
    vim.notify("Cannot source: " .. bufname, vim.log.levels.ERROR)
    return
  end
  return ":source %" -- without <CR> to confirm manually
end, { expr = true, desc = "save and source" })

-- mappings: window
local function win_move_or_cmd(row, col, cmd)
  if not require("atusy.misc").move_floatwin(row, col) then
    vim.cmd("wincmd " .. cmd)
  end
end

set_keymap({ "", "t" }, "<C-Up>", function()
  win_move_or_cmd(-1, 0, "2+")
end)
set_keymap({ "", "t" }, "<C-Down>", function()
  win_move_or_cmd(1, 0, "2-")
end)
set_keymap({ "", "t" }, "<C-Right>", function()
  win_move_or_cmd(0, 2, "2>")
end)
set_keymap({ "", "t" }, "<C-Left>", function()
  win_move_or_cmd(0, -2, "2<")
end)

-- mappings: macro
-- disable macro a-z except q on normal mode and entirely on visual mode
set_keymap("x", "q", "<Nop>")
set_keymap("n", "q", function()
  local reg = vim.fn.reg_recording()
  if reg ~= "" then
    return 'q<cmd>echo "stop recording @' .. reg .. '"<cr>'
  end
  local char = vim.fn.getcharstr(0)
  if not char then
    return "<Ignored>"
  end
  if char == "q" or not char:match("[a-z]") then
    return "q" .. char
  end
  vim.notify("q[a-z] are disabled except qq", vim.log.levels.ERROR)
  return "<Ignored>"
end, {
  expr = true,
  nowait = true,
})

--[[ autocmd ]]
vim.api.nvim_create_autocmd("TermOpen", { pattern = "*", group = utils.augroup, command = "startinsert" })

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "c:*",
  group = utils.augroup,
  desc = "cleanup cmdline history which are short enough or prefixed by space",
  callback = function()
    local hist = vim.fn.histget(":", -1)
    if not hist then
      return
    end
    if
      hist:match("^[a-zA-Z]+$")
      or hist:match("^..?!?$")
      or hist:match("^wqa!?$")
      or hist == "source %"
      or hist:sub(0, 1) == " "
    then
      vim.fn.histdel(":", -1)
    end
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  desc = "Toggle cursorline on InsertEnter/Leave iff cursorline is set on normal mode",
  group = utils.augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    local wo = vim.wo[win]
    if not wo.cursorline then
      return
    end
    wo.cursorline = false
    vim.api.nvim_create_autocmd("ModeChanged", {
      -- InsertLeave is not adequate because <C-C> won't trigger it
      pattern = "i:*",
      once = true,
      group = vim.api.nvim_create_augroup("toggle-cursorline", {}),
      callback = function()
        pcall(vim.api.nvim_set_option_value, "cursorline", true, { win = win })
      end,
    })
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  command = "lua pcall(vim.highlight.on_yank)",
  group = utils.augroup,
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
  once = true,
  callback = function()
    vim.filetype.add({
      extension = {
        gitcommit = "gitcommit",
        tf = "terraform",
      },
      filename = {
        [".envrc"] = "sh",
        [".profile"] = "sh",
      },
      pattern = {
        ["${HOME}/%.local/share/chezmoi/.*"] = {
          function(path, bufnr)
            local filename, cnt = path:gsub("/dot_", "/.")
            if cnt == 0 then
              return
            end
            return vim.filetype.match({ filename = filename, buf = bufnr })
          end,
          { priority = -math.huge },
        },
        ["Dockerfile[._].*"] = { "dockerfile", { priority = -math.huge } },
      },
    })
  end,
})

--[[ Terminal ]]
-- nvim-remote for edit-commandline zle
if vim.fn.executable("nvr") == 1 then
  vim.env.EDITOR_CMD = [[nvr -cc "above 5split" --remote-wait-silent +"setlocal bufhidden=wipe filetype=zsh.nvr-zsh"]]
  vim.api.nvim_create_autocmd("FileType", {
    desc = "Go back to the terminal window on WinClosed. Otherwise, the current window to leftest above",
    group = utils.augroup,
    pattern = { "zsh.nvr-zsh" },
    callback = function(args)
      vim.schedule(function()
        local parent = vim.fn.win_getid(vim.fn.winnr("#"))
        -- local local_group = vim.api.nvim_create_augroup(args.file, {})
        vim.api.nvim_create_autocmd("WinClosed", {
          -- group = local_group,
          buffer = args.buf,
          once = true,
          callback = function()
            vim.schedule(function()
              local ok = pcall(vim.api.nvim_set_current_win, parent)
              if ok then
                vim.cmd.startinsert()
              end
            end)
          end,
        })
      end)
    end,
    nested = true,
  })
end