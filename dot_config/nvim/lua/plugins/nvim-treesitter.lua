local augroup = vim.api.nvim_create_augroup("atusy.plugins.nvim-treesitter", {})
local treesitter_path = vim.fs.joinpath(vim.fn.stdpath("data"), "/treesitter")

---@param cb fun(parser_path: string): nil
local function with_parser_dir(cb)
	local parser_dir = vim.fs.joinpath(treesitter_path, "parser")
	vim.uv.fs_mkdir(parser_dir, tonumber("755", 8), function()
		if cb then
			cb(parser_dir)
		end
	end)
end

return {
	{
		"https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = function()
			require("nvim-treesitter").update()
		end,
		lazy = true,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				group = augroup,
				callback = function(ctx)
					require("nvim-treesitter")
					local ok = pcall(vim.treesitter.query.get, ctx.match, "highlights")
					if not ok then
						return
					end
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					pcall(vim.treesitter.start)
				end,
			})
		end,
		config = function()
			-- install directory of treesitter parsers
			vim.opt.runtimepath:prepend(treesitterpath)

			-- add non-official parsers
			local parser_config = require("nvim-treesitter.parsers")
			local parser_uri = vim.uv.os_homedir() .. "/ghq/github.com/atusy/tree-sitter-uri"
			if not vim.uv.fs_stat(parser_uri) then
				parser_uri = "https://github.com/atusy/tree-sitter-uri"
			end
			parser_config.uri = {
				install_info = {
					url = parser_uri,
					branch = "main",
					files = { "src/parser.c" },
					generate_requires_npm = false, -- if stand-alone parser without npm dependencies
					requires_generate_from_grammar = false, -- if folder contains pre-generated src/parser.c
				},
				filetype = "uri", -- if filetype does not match the parser name
			}
			parser_config.unifieddiff = {
				install_info = {
					url = "https://github.com/monaqa/tree-sitter-unifieddiff",
					branch = "master",
					files = { "src/parser.c", "src/scanner.c" },
				},
				filetype = "diff", -- if filetype does not agrees with parser name
			}

			-- setup
			require("nvim-treesitter").setup({ install_dir = treesitter_path })

			-- register parsers to some other languages
			vim.treesitter.language.register("bash", "zsh")
			vim.treesitter.language.register("bash", "sh")
			vim.treesitter.language.register("json", "jsonl")
			vim.treesitter.language.register("json", "ndjson")
			vim.treesitter.language.register("hcl", "tf")
			vim.treesitter.language.register("markdown", "rmd")
			vim.treesitter.language.register("markdown", "qmd")

			-- custom highlights
			local function hi()
				vim.api.nvim_set_hl(0, "@illuminate", { bg = "#383D47" })
			end

			hi()
			vim.api.nvim_create_autocmd(
				"ColorScheme",
				{ group = vim.api.nvim_create_augroup("atusy.nvim-treesitter", {}), callback = hi }
			)
		end,
	},
	{
		"https://github.com/monaqa/tree-sitter-unifieddiff",
		filetype = { "unifieddiff", "gin-diff" },
		init = function(opts)
			with_parser_dir(function(parser_path)
				vim.system(
					{ "tree-sitter", "build", "--output", vim.fs.joinpath(parser_path, "unifieddiff.so") },
					{ cwd = opts.dir },
					function() end
				)
			end)
		end,
		config = function()
			vim.treesitter.language.register("unifieddiff", "gin-diff")
		end,
	},
	{
		"https://github.com/atusy/tree-sitter-uri",
		build = function(opts)
			with_parser_dir(function(parser_path)
				vim.system(
					{ "tree-sitter", "build", "--output", vim.fs.joinpath(parser_path, "uri.so") },
					{ cwd = opts.dir },
					function() end
				)
			end)
		end,
	},
}
