local M = {}

M.deno_installed = false

function M.get_deno(version)
	version = version or "1.38.4"
	local cache = vim.fn.stdpath("cache") --[[@as string]]
	local base = vim.fs.joinpath(cache, "denops", "deno", version)
	local bin = vim.fs.joinpath(base, "bin", "deno")
	if not vim.uv.fs_stat(bin) then ---@diagnostic disable-line: undefined-field
		local obj = require("atusy.bin.deno").install(version, { env = { DENO_INSTALL = base } }):wait()
		if obj.code ~= 0 then
			error(obj.stderr) -- requires unzip
		end
	end
	return bin, vim.fs.joinpath(base, "cache")
end

local cached = {}

---Deno cache efficiently for denops plugins
---
---Use this as early as possible if plugins blocks user input during cache (e.g., skkeleton)
---@param x string | table i.e. Lazyspec
---@param force? boolean
function M.cache_plugin(x, force)
	if M.deno_installed or force then
		local dir = type(x) == "table" and require("atusy.lazy").dir(x) or x
		if not cached[dir] then
			require("atusy.bin.deno").cache_dir(dir)
			cached[dir] = true
		end
	end
end

return M
