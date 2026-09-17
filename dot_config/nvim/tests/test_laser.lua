local MiniTest = require("mini.test")
local expect = MiniTest.expect
if not pcall(require, "laser.position") then
	return MiniTest.new_set({ hooks = {
		pre_case = function()
			MiniTest.skip("LASER_NVIM_PATH is required")
		end,
	} })
end
local saved, configs, text, options

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			saved = { config = vim.lsp.config, laser = package.loaded.laser, fn = {} }
			for _, name in ipairs({ "mode", "getcmdtype", "getcmdline", "getcmdpos", "pum#set_option" }) do
				saved.fn[name] = vim.fn[name]
			end
			text = "lua vim"
			vim.fn.mode = function()
				return "c"
			end
			vim.fn.getcmdtype = function()
				return ":"
			end
			vim.fn.getcmdline = function()
				return text
			end
			vim.fn.getcmdpos = function()
				return #text + 1
			end
			vim.fn["pum#set_option"] = function() end
			package.loaded.laser = {
				complete = function(opts)
					options = opts
				end,
			}
			configs = setmetatable({}, {
				__call = function(self, name, config)
					self[name] = config
				end,
			})
			for _, name in ipairs({ "nvim-cmdline", "nvim-input", "nvim-cmdline-history" }) do
				configs[name] = {
					filetypes = { "ddc_cmdline" },
					cmd = function()
						return {
							request = function(_, params)
								return params
							end,
						}
					end,
				}
			end
			vim.lsp.config = configs
		end,
		post_case = function()
			vim.lsp.config = saved.config
			package.loaded.laser = saved.laser
			for name, fn in pairs(saved.fn) do
				vim.fn[name] = fn
			end
			pcall(vim.api.nvim_del_augroup_by_name, "atusy.laser")
			for _, key in ipairs({ "<Tab>", "<S-Tab>", "<C-Y>", "<C-C>" }) do
				pcall(vim.keymap.del, { "i", "c" }, key)
			end
		end,
	},
})

T["history completion preserves the command prefix"] = function()
	require("atusy.laser").setup()
	local params = configs["nvim-cmdline-history"].cmd({}).request("textDocument/completion", {
		position = { line = 0, character = #text },
	})
	local provider = require("atusy.lsp.ddc_completion").make_history_provider({
		gethistory = function()
			return { "lua vim.ui.open()", "checkhealth vim.lsp" }
		end,
	}, 1000)
	expect.equality(provider(params, { text = text }).items, { { label = "vim.ui.open()" } })
end

return T
