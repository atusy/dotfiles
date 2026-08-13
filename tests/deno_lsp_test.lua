local deno = dofile("dot_config/nvim/lua/atusy/lsp/deno.lua")

deno.setup()

local autocmds = vim.api.nvim_get_autocmds({ group = "atusy.lsp.deno" })
assert(#autocmds == 1, "Deno integration must leave cached modules to kakehashi")
assert(autocmds[1].event == "BufReadCmd", "Deno integration must only intercept deno: URIs")
