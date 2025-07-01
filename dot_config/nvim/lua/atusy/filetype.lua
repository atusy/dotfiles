local M = {}

function M.add()
	vim.filetype.add({
		extension = {
			gitcommit = "gitcommit",
			tf = "terraform",
		},
		filename = {
			[".envrc"] = "sh",
			[".profile"] = "sh",
		},
		pattern = {
			["${HOME}/%.local/share/chezmoi/.*"] = {
				function(path, bufnr)
					local filename, cnt = path:gsub("/dot_", "/.")
					if cnt == 0 then
						return
					end
					return vim.filetype.match({ filename = filename, buf = bufnr })
				end,
				{ priority = -math.huge },
			},
			["Dockerfile[._].*"] = { "dockerfile", { priority = -math.huge } },
			[".*"] = {
				function(_, bufnr)
					local shebang = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
					if not shebang or shebang:sub(1, 2) ~= "#!" then
						return
					end
					shebang = shebang:gsub("%s+", " ")

					local idx_space = shebang:find(" ")
					local path = string.sub(shebang, 3, idx_space and idx_space - 1 or nil)
					local cmd = vim.fs.basename(path)
					if cmd == "deno" then
						return "typescript"
					end
					if path == "/usr/bin/env" then
						if
							vim.startswith(shebang, "#!/usr/bin/env deno")
							or vim.startswith(shebang, "#!/usr/bin/env -S deno")
						then
							return "typescript"
						end
					end
				end,
				{ priority = -math.huge },
			},
		},
	})
end

return M
