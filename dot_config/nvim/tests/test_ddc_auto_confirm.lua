local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set()

-- Fake the pum.vim / denops surface so the test can observe ordering:
-- the fake denops request rewrites ":smile:" at end-of-line into the emoji,
-- so the emoji only appears if confirmation runs BEFORE the typed char lands.
local function setup_fakes()
	vim.g.fake_pum_visible = false
	vim.g.confirm_calls = 0
	vim.g.denops_requests = {}
	vim.g.deferred_complete_dones = 0
	local root = vim.fn.tempname()
	local autoloads = {
		["pum.vim"] = [[
			let s:pum = #{cursor: -1, current_word: ''}
			function! pum#_fake_open() abort
				let s:pum = #{cursor: 1, current_word: ':smile:'}
				let g:fake_pum_visible = v:true
			endfunction
			function! pum#_get() abort
				return s:pum
			endfunction
			function! pum#visible() abort
				return g:fake_pum_visible
			endfunction
			function! pum#complete_info() abort
				if !g:fake_pum_visible || s:pum.cursor <= 0 || s:pum.current_word ==# ''
					return #{selected: -1, inserted: ''}
				endif
				return #{selected: s:pum.cursor - 1, inserted: s:pum.current_word}
			endfunction
			function! pum#current_item() abort
				return pum#complete_info().selected >= 0
					\ ? #{word: ':smile:', user_data: #{lspitem: '{}'}}
					\ : {}
			endfunction
			function! pum#_fake_close() abort
				" Mirrors pum#close(): it schedules a deferred complete-done event
				" (later notified to ddc) whenever a candidate is still active.
				if s:pum.cursor >= 0 && s:pum.current_word !=# ''
					let g:deferred_complete_dones += 1
				endif
				let g:fake_pum_visible = v:false
				let s:pum = #{cursor: -1, current_word: ''}
			endfunction
		]],
		["pum/map.vim"] = [[
			function! pum#map#confirm() abort
				let g:confirm_calls += 1
				call pum#_fake_close()
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
	-- pum.vim installs its own InsertCharPre handler (s:check_user_input) that
	-- closes the popup on any typed char; it runs AFTER the module's handler
	-- because it is registered later (at selection time).
	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = vim.api.nvim_create_augroup("fake-pum-temp", {}),
		callback = function()
			if vim.g.fake_pum_visible then
				vim.fn["pum#_fake_close"]()
			end
		end,
	})
	vim.api.nvim_feedkeys(vim.keycode("A x<Esc>"), "x", false)
	return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

T["typing while a candidate is selected confirms it before the char"] = function()
	setup_fakes()
	vim.fn["pum#_fake_open"]()

	expect.equality(type_after_inserted_word(), { "😄 x" })
	expect.equality(vim.g.denops_requests, { { "ddc", "onCompleteDone" } })
end

T["typing without a selection inserts the char unchanged"] = function()
	setup_fakes()

	expect.equality(type_after_inserted_word(), { ":smile: x" })
	expect.equality(vim.g.confirm_calls, 0)
	expect.equality(vim.g.denops_requests, {})
end

T["confirming leaves no deferred complete-done to notify ddc again"] = function()
	setup_fakes()
	vim.fn["pum#_fake_open"]()

	type_after_inserted_word()

	-- pum#close()'s deferred complete-done would notify ddc's onCompleteDone a
	-- second time, racing the synchronous request and double-applying the
	-- textEdit (observed as LSPRangeError from #restoreRequestedState).
	expect.equality(vim.g.deferred_complete_dones, 0)
end

T["typing after a selected SKK candidate preserves dictionary learning"] = function()
	setup_fakes()
	vim.fn["pum#_fake_open"]()
	local previous = package.loaded["atusy.lsp.skkelua"]
	local learned = 0
	package.loaded["atusy.lsp.skkelua"] = {
		on_complete_done = function()
			learned = learned + 1
		end,
	}
	type_after_inserted_word()
	package.loaded["atusy.lsp.skkelua"] = previous
	expect.equality(learned, 1)
end

return T
