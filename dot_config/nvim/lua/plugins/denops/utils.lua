local M = {}

function M.get_deno(version)
	version = version or "1.38.4"
	local cache = vim.fn.stdpath("cache") --[[@as string]]
	local base = vim.fs.joinpath(cache, "denops", "deno", version)
	local bin = vim.fs.joinpath(base, "bin", "deno")
	if not vim.uv.fs_stat(bin) then
		local obj = require("atusy.bin.deno").install(version, { env = { DENO_INSTALL = base } }):wait()
		if obj.code ~= 0 then
			error(obj.stderr) -- requires unzip
		end
	end
	return bin, vim.fs.joinpath(base, "cache")
end

---Deno cache for denops plugins
---@param x string | table | nil i.e. Lazyspec
---@param reload boolean | nil
function M.cache_plugin(x, reload)
	local dir = type(x) == "table" and require("atusy.lazy").dir(x) or x or require("lazy.core.config").root
	if type(dir) ~= "string" then
		return
	end
	require("atusy.bin.deno").cache_dir(dir, vim.g["denops#deno"], vim.g["denops#deno_dir"], reload)
end

return M
