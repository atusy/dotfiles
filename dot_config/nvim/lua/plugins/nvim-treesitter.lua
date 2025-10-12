local augroup = vim.api.nvim_create_augroup("atusy.plugins.nvim-treesitter", {})
local treesitter_path = vim.fs.joinpath(vim.fn.stdpath("data"), "treesitter")

---@param cb fun(parser_path: string): nil
local function with_parser_dir(cb)
	local parser_dir = vim.fs.joinpath(treesitter_path, "parser")
	vim.uv.fs_mkdir(parser_dir, tonumber("755", 8), function()
		if cb then
			cb(parser_dir)
		end
	end)
end

local function install_parser_unifieddiff(src, force)
	with_parser_dir(function(parser_path)
		local output = vim.fs.joinpath(parser_path, "unifieddiff.so")
		if force or not vim.uv.fs_stat(output) then
			vim.system({ "tree-sitter", "build", "--output", output }, { cwd = src }, function() end)
		end
	end)
end

local function install_parser_uri(src, force)
	with_parser_dir(function(parser_path)
		local output = vim.fs.joinpath(parser_path, "uri.so")
		if force or not vim.uv.fs_stat(output) then
			vim.system({ "tree-sitter", "build", "--output", output }, { cwd = src }, function() end)
		end
	end)
end

return {
	{
		"https://github.com/nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = function()
			local ok, err = pcall(function()
				local installed = require("nvim-treesitter").get_installed()
				local available = require("nvim-treesitter.config").get_available()
				local target = vim.tbl_filter(function(lang)
					vim.tbl_contains(available, lang)
				end, installed)
				require("nvim-treesitter").update(target)
			end)
			if not ok then
				vim.notify(err or "failed to update parsers", vim.log.levels.ERROR, { title = "nvim-treesitter" })
			end
		end,
		lazy = true,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				group = augroup,
				callback = function(ctx)
					require("nvim-treesitter")
					local ok = pcall(vim.treesitter.start, ctx.buf)
					if ok then
						return
					end

					-- on fail, retry after installing the parser
					local lang = vim.treesitter.language.get_lang(ctx.match)
					require("nvim-treesitter").install({ lang }):await(function(err)
						if err then
							vim.notify(err, vim.log.levels.ERROR, { title = "nvim-treesitter" })
						end
						pcall(vim.treesitter.start, ctx.buf)
					end)
				end,
			})
		end,
		config = function()
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
				vim.api.nvim_set_hl(0, "@illuminate", { link = "LspReferenceTarget" })
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
		filetype = { "diff", "gin-diff" },
		build = function(opts)
			install_parser_unifieddiff(opts.dir, true)
		end,
		init = function(opts)
			install_parser_unifieddiff(opts.dir, false)
		end,
		config = function()
			vim.treesitter.language.register("unifieddiff", "diff")
			vim.treesitter.language.register("unifieddiff", "gin-diff")
		end,
	},
	{
		"https://github.com/atusy/tree-sitter-uri",
		lazy = true,
		build = function(opts)
			install_parser_uri(opts.dir, true)
		end,
		init = function(opts)
			install_parser_uri(opts.dir, false)
		end,
	},
}
