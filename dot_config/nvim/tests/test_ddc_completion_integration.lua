local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set()

T["all local identities attach once and return isolated results"] = function()
	if vim.env.DDC_SOURCE_NVIM_LSP_PATH == nil then
		MiniTest.skip("DDC_SOURCE_NVIM_LSP_PATH is required")
	end
	local completion = require("atusy.lsp.ddc_completion")
	local cmdline = require("ddc_source_nvim_lsp.cmdline")
	completion.setup()
	vim.fn.histadd(":", "git status")

	local cases = {
		{
			filetype = "ddc_input",
			name = "nvim-input",
			text = "v:co",
			metadata = { cmdType = "=", completionType = "", completePos = 0, generation = 1 },
		},
		{
			filetype = "ddc_cmdline_history",
			name = "nvim-cmdline-history",
			text = "git s",
			metadata = { cmdType = ":", completionType = "shellcmd", completePos = 4, generation = 1 },
		},
		{
			filetype = "ddc_cmdline",
			name = "nvim-cmdline",
			text = "ed",
			metadata = { cmdType = ":", completionType = "command", completePos = 0, generation = 1 },
		},
	}

	local buffers = {}
	for _, case in ipairs(cases) do
		local document = cmdline.ensure_buffer(case.filetype)
		cmdline.set_lines(document.bufnr, case.text)
		expect.equality(
			vim.wait(3000, function()
				return #vim.lsp.get_clients({ bufnr = document.bufnr, name = case.name }) == 1
			end),
			true
		)
		local clients = vim.lsp.get_clients({ bufnr = document.bufnr })
		expect.equality(
			vim.tbl_map(function(client)
				return client.name
			end, clients),
			{ case.name }
		)
		local response = clients[1]:request_sync("textDocument/completion", {
			textDocument = { uri = document.uri },
			position = { line = 0, character = #case.text },
			xDdc = case.metadata,
		}, 1000, document.bufnr)
		expect.equality(response.err, nil)
		expect.equality(#response.result.items > 0, true)
		table.insert(buffers, document.bufnr)
	end

	expect.no_equality(buffers[1], buffers[2])
	expect.no_equality(buffers[2], buffers[3])
end

return T
