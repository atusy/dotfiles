local state = {
	public = {}, ---@type table<string, boolean>
}

return {
	{
		"https://github.com/olimorris/codecompanion.nvim",
		lazy = true,
		event = "CmdlineEnter",
		init = function()
			vim.keymap.set({ "n", "x" }, "<plug>(s)c", ":CodeCompanionChat ")
			vim.keymap.set({ "n", "x" }, "<plug>(s)i", ":CodeCompanion ")
			vim.keymap.set("n", "<plug>(s)n", function()
				require("plugins.codecompanion.navi").start()
			end)
		end,
		config = function()
			local function optimus()
				return require("codecompanion.adapters").extend("openrouter", {
					name = "openrouter/gemini-2-0-flash",
					formatted_name = "openrouter/gemini-2-0-flash",
					schema = { model = { default = "google/gemini-2.0-flash-exp:free" } },
				})
			end
			require("codecompanion").setup({
				adapters = {
					openrouter = require("plugins.codecompanion.adapter.openrouter"),
					optimus = optimus,
					default = function()
						-- change adapter based on repo visibility
						local cwd = vim.fn.getcwd()
						if state.public[cwd] == nil then
							local res = vim.system({
								"gh",
								"repo",
								"view",
								"--json",
								"visibility",
								"--jq",
								".visibility",
							}):wait()
							state.public[cwd] = res.code == 0 and res.stdout:match("PUBLIC\n*")
						end
						if state.public[cwd] then
							return optimus()
						else
							return require("codecompanion.adapters").extend("copilot", {})
						end
					end,
				},
				strategies = {
					chat = {
						adapter = "default",
						tools = {
							["mcp"] = {
								-- Prevent mcphub from loading before needed
								callback = function()
									return require("mcphub.extensions.codecompanion")
								end,
								description = "Call tools and resources from the MCP Servers",
							},
							opts = {
								auto_submit_success = true,
							},
						},
						keymaps = {
							yank_code = {
								modes = {
									n = "<Plug>(ignored)",
								},
								index = 7,
								callback = "keymaps.yank_code",
								description = "Yank Code",
							},
						},
					},
					inline = {
						adapter = "default",
					},
					agent = {
						adapter = "default",
					},
				},
				display = {
					action_palette = {
						provider = "telescope",
					},
				},
			})
		end,
	},
}
