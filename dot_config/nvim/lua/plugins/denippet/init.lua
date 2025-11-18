return {
	"https://github.com/uga-rosa/denippet.vim",
	config = function()
		local snippetsdir = vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "snippets")
		local function load(file, filetypes)
			vim.fn["denippet#load"](vim.fs.joinpath(snippetsdir, file), filetypes)
		end
		load("markdown.toml", { "markdown" })
	end,
}
