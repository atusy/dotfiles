return {
	{
		"https://github.com/olimorris/codecompanion.nvim",
		lazy = true,
		event = "CmdlineEnter",
		init = function()
			vim.keymap.set({ "n", "x" }, "<plug>(s)c", ":CodeCompanionChat ")
			vim.keymap.set({ "n", "x" }, "<plug>(s)i", ":CodeCompanion ")
		end,
		config = function()
			require("codecompanion").setup({
				adapters = {
					openrouter = require("plugins.codecompanion.adapter.openrouter"),
					optimus = function()
						return require("codecompanion.adapters").extend("openrouter", {
							schema = { model = { default = "openrouter/optimus-alpha" } },
						})
					end,
				},
				strategies = {
					chat = {
						adapter = "copilot",
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
						adapter = "copilot",
					},
					agent = {
						adapter = "copilot",
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
