local MiniTest = require("mini.test")
local expect = MiniTest.expect
if not pcall(require, "laser.position") then
	return MiniTest.new_set({
		hooks = {
			pre_case = function()
				MiniTest.skip("LASER_NVIM_PATH is required")
			end,
		},
	})
end
local saved, configs, text, options

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			saved = { config = vim.lsp.config, laser = package.loaded.laser, skkelua = package.loaded.skkelua, fn = {} }
			for _, name in ipairs({ "mode", "getcmdtype", "getcmdline", "getcmdpos" }) do
				saved.fn[name] = vim.fn[name]
			end
			package.loaded.skkelua = nil
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
					filetypes = { "nvim_cmdline" },
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
			package.loaded.skkelua = saved.skkelua
			for name, fn in pairs(saved.fn) do
				vim.fn[name] = fn
			end
			pcall(vim.api.nvim_del_augroup_by_name, "plugins.laser")
			for _, key in ipairs({ "<Tab>", "<S-Tab>", "<C-Y>", "<C-C>" }) do
				pcall(vim.keymap.del, { "i", "c" }, key)
			end
		end,
	},
})

T["history completion preserves the command prefix"] = function()
	require("plugins.laser").setup()
	local params = configs["nvim-cmdline-history"].cmd({}).request("textDocument/completion", {
		position = { line = 0, character = #text },
	})
	local provider = require("atusy.lsp.cmdline_completion").make_history_provider({
		gethistory = function()
			return { "lua vim.ui.open()", "checkhealth vim.lsp" }
		end,
	}, 1000)
	expect.equality(provider(params, { text = text }).items, { { label = "vim.ui.open()" } })
end

T["history matches prefixes and preserves recency"] = function()
	require("plugins.laser").complete()
	local candidates = vim.tbl_map(function(label)
		return { abbr = label, word = label, user_data = { laser = { item = { label = label } } } }
	end, { "vim.z", "vim.a", "view.map" })
	local filtered = require("laser.filter").apply(
		candidates,
		"vim",
		require("laser.clients").resolve("nvim-cmdline-history", options.clientOptions)
	)
	expect.equality(
		vim.tbl_map(function(item)
			return item.word
		end, filtered),
		{ "vim.z", "vim.a" }
	)
end

T["completion menus identify providers without losing descriptions"] = function()
	require("plugins.laser").complete()
	local get_client = vim.lsp.get_client_by_id
	local names = { "nvim-cmdline", "nvim-input", "nvim-cmdline-history", "skkelua", "kakehashi" }
	vim.lsp.get_client_by_id = function(id)
		return { name = names[id] }
	end
	local menus = {}
	for id, name in ipairs(names) do
		local item = {
			word = "vim",
			abbr = "vim",
			menu = "description",
			user_data = { laser = { client_id = id, item = { label = "vim" } } },
		}
		local filtered = require("laser.filter").apply(
			{ item },
			"vim",
			require("laser.clients").resolve(name, options.clientOptions)
		)
		menus[#menus + 1] = filtered[1].menu
	end
	vim.lsp.get_client_by_id = get_client
	expect.equality(menus, {
		"[CMD] description",
		"[INPUT] description",
		"[HIST] description",
		"[SKK] description",
		"[kakehashi] description",
	})
end

T["clients follow the mode and skkelua state"] = function()
	local clients = {}
	for id, name in ipairs({ "skkelua", "lua_ls", "nvim-cmdline", "nvim-input", "nvim-cmdline-history" }) do
		clients[id] = { id = id, name = name }
	end
	for _, case in ipairs({
		{ "i", "", { "lua_ls" } },
		{ "c", ":", { "nvim-cmdline", "lua_ls", "nvim-cmdline-history" } },
		{ "c", "@", { "nvim-input", "lua_ls", "nvim-cmdline-history" } },
		{ "c", ">", { "nvim-input", "lua_ls", "nvim-cmdline-history" } },
		{ "c", "=", { "nvim-input" } },
		{ "c", "/", { "lua_ls" } },
		{ "c", "?", { "lua_ls" } },
		{ "c", "-", { "lua_ls" } },
	}) do
		vim.fn.mode = function()
			return case[1]
		end
		vim.fn.getcmdtype = function()
			return case[2]
		end
		for _, state in ipairs({ "unloaded", "disabled", "enabled" }) do
			package.loaded.skkelua = state ~= "unloaded"
					and {
						is_enabled = function()
							return state == "enabled"
						end,
						phase = function()
							return "input"
						end,
					}
				or nil
			require("plugins.laser").complete()
			expect.equality(options.clientOptions.skkelua.max_items, 30)
			local expected = state == "enabled" and { "skkelua" } or case[3]
			expect.equality(
				vim.tbl_map(function(client)
					return client.name
				end, require("laser.clients").select(clients, options.clients, options.clientOptions)),
				expected
			)
		end
	end
end

return T
