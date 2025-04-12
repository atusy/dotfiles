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
				{ bufnr = buf, async = true, lsp_format = "fallback", notify_on_error = false },
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
				{ bufnr = args.buf, async = false, lsp_format = "fallback", timeout_ms = 200, notify_on_error = false },
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
		event = "BufWritePre", -- "BufWriteCmd"
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- format with gq{motion}
			vim.keymap.set("n", "gqq", function()
				-- for original gqq, use gqgq
				require("conform").format({ async = true, lsp_format = "fallback" })
			end)
			if false then
				-- enable if slow formatter exists, and disable format_on_save
				format_on_buf_write_pre()
			end
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					local opt = require("atusy.opt").format_on_save
					if opt ~= false then
						require("conform").format({ bufnr = args.buf })
					end
				end,
			})
		end,
		config = function()
			local biome = {
				"biome-organize-imports",
				"biome-check",
				"biome",
			}

			require("conform").setup({
				default_format_opts = {
					lsp_format = "fallback",
					timeout_ms = 500,
				},
				formatters_by_ft = {
					go = { "goimports", lsp_format = "last" }, -- to use gofumpt via LSP
					javascript = biome,
					lua = { "stylua" },
					typescript = function(buf)
						local project_dir = vim.fn.getcwd()
						local lsp_clients = vim.lsp.get_clients({ bufnr = buf })

						for _, client in ipairs(lsp_clients) do
							if client.name == "denols" then
								return { lsp_format = "prefer" }
							end
							if client.name == "tsserver" then
								project_dir = client.config.root_dir
								break
							end
						end

						-- use prettier if package.json contains prettier as a dependency
						local package_json = vim.fs.joinpath(project_dir, "package.json")
						if vim.fn.filereadable(package_json) == 1 then
							local package = vim.fn.json_decode(vim.fn.readfile(package_json))
							if package and package.devDependencies and package.devDependencies.prettier then
								return { "prettier" }
							end
						end

						-- otherwise, use biome
						return biome
					end,
					nix = { "nixfmt" },
					python = { "ruff_format", "ruff_fix" },
					r = { "air", "styler", stop_after_first = true },
				},
			})
		end,
	},
}
