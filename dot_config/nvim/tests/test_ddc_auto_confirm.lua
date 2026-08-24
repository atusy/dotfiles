local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set()

-- Fake the pum.vim / denops surface so the test can observe ordering:
-- the fake denops request rewrites ":smile:" at end-of-line into the emoji,
-- so the emoji only appears if confirmation runs BEFORE the typed char lands.
local function setup_fakes()
	vim.g.fake_pum_visible = true
	vim.g.confirm_calls = 0
	vim.g.denops_requests = {}
	local root = vim.fn.tempname()
	local autoloads = {
		["pum.vim"] = [[
			function! pum#visible() abort
				return g:fake_pum_visible
			endfunction
			function! pum#complete_info() abort
				return #{selected: 0, inserted: ':smile:'}
			endfunction
			function! pum#current_item() abort
				return #{word: ':smile:', user_data: #{lspitem: '{}'}}
			endfunction
		]],
		["pum/map.vim"] = [[
			function! pum#map#confirm() abort
				let g:confirm_calls += 1
				let g:fake_pum_visible = v:false
				return ''
			endfunction
		]],
		["denops.vim"] = [[
			function! denops#request(name, method, args) abort
				call add(g:denops_requests, [a:name, a:method])
				call setline('.', substitute(getline('.'), ':smile:$', "\U0001F604", ''))
				call cursor(1, col('$'))
				return v:null
			endfunction
		]],
	}
	for path, source in pairs(autoloads) do
		local file = vim.fs.joinpath(root, "autoload", path)
		vim.fn.mkdir(vim.fs.dirname(file), "p")
		vim.fn.writefile(vim.split(source, "\n"), file)
	end
	vim.opt.runtimepath:prepend(root)
end

-- Type " x" after the inserted-but-unconfirmed word and return the buffer line.
local function type_after_inserted_word()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { ":smile:" })
	require("atusy.ddc.auto_confirm").setup()
	vim.api.nvim_feedkeys(vim.keycode("A x<Esc>"), "x", false)
	return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

T["typing while a candidate is selected confirms it before the char"] = function()
	setup_fakes()

	expect.equality(type_after_inserted_word(), { "😄 x" })
	expect.equality(vim.g.confirm_calls, 1)
	expect.equality(vim.g.denops_requests, { { "ddc", "onCompleteDone" } })
end

T["typing without a selection inserts the char unchanged"] = function()
	setup_fakes()
	vim.g.fake_pum_visible = false

	expect.equality(type_after_inserted_word(), { ":smile: x" })
	expect.equality(vim.g.confirm_calls, 0)
	expect.equality(vim.g.denops_requests, {})
end

return T
