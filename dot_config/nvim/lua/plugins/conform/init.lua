local augroup = vim.api.nvim_create_augroup("atusy.conform", {})

local function format_error(err, n)
	n = n or math.huge
	local content = {}
	for line in err:gmatch("[^\n]*") do
		if line == "stack trackback:" then
			break
		end
		table.insert(content, line)
		if #content == n then
			break
		end
	end
	return table.concat(content, "\n")
end

local function format_on_buf_write_post(buf, once)
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		buffer = buf,
		once = once,
		callback = function()
			pcall(
				require("conform").format,
				{ bufnr = buf, async = true, lsp_fallback = true, notify_on_error = false },
				function(err)
					if err == nil then
						vim.cmd.up()
					elseif err:match("No formatters found for buffer") then
						return
					elseif err == "No result returned from LSP formatter" then
						return
					else
						vim.notify(format_error(err, 1), vim.log.levels.ERROR)
					end
				end
			)
		end,
	})
end

local function format_on_buf_write_pre(buf, once)
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = buf,
		once = once,
		callback = function(args)
			local opt = require("atusy.opt").format_on_save
			if opt == false then
				return
			elseif opt == "table" and (opt[vim.o.filetype] == false or opt[1] == false) then
				return
			end
			pcall(
				require("conform").format,
				{ bufnr = args.buf, async = false, lsp_fallback = true, timeout_ms = 200, notify_on_error = false },
				function(err)
					if err == nil then
						return
					elseif err == "No formatters available for buffer" then
						return
					elseif err == "No result returned from LSP formatter" then
						return
					elseif err:match("No formatters found for buffer") then
						return
					elseif err:match("Formatter '.-' timeout") or err:match("%[LSP%]%[.-%] timeout") then
						format_on_buf_write_post(args.buf, true) -- as retry
					else
						vim.notify(format_error(err, 1), vim.log.levels.ERROR)
					end
				end
			)
		end,
	})
end

return {
	{
		"https://github.com/stevearc/conform.nvim",
		lazy = true,
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- format with gq{motion}
			vim.keymap.set("n", "gqq", function()
				-- for original gqq, use gqgq
				require("conform").format({ async = true, lsp_fallback = true })
			end)
			format_on_buf_write_pre()
		end,
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "ruff_format", "ruff_fix" }, -- black and isort are toooooo slow!
					javascript = { { "prettierd", "prettier" } },
					go = { "goimports", { "gofumpt", "gofmt" } },
				},
			})
		end,
	},
}
