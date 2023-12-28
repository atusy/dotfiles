local M = {}

---@return vim.SystemObj install_process, string deno_binary_path
function M.install(version, opts, on_exit)
	opts = opts or {}
	opts.env = opts.env or {}
	opts.env.DENO_INSTALL = opts.env.DENO_INSTALL or vim.fs.joinpath(vim.uv.os_homedir(), ".local")
	local src = [[curl -fsSL https://deno.land/x/install/install.sh | sh /dev/stdin%s]]
	local args = (version == nil or version == "latest") and "" or (" v" .. version)
	local obj = vim.system({ "sh", "-c", src:format(args) }, opts, on_exit)
	return obj, vim.fs.joinpath(opts.env.DENO_INSTALL, "bin/deno")
end

M.cache_pending = {} ---@type table<string, true>
M.cache_ongoing = 0

---Deno cache asyncronously
---
---Queues a ts file to be cached, and parallelly consumes up to 5 queued files.
---The consumption order may be inconsitent with the queued order.
function M.cache(ts, bin, cache)
	if M.cache_ongoing > 5 then
		M.cache_pending[ts] = true
		return
	end
	M.cache_ongoing = M.cache_ongoing + 1
	return vim.system({ bin or "deno", "cache", ts }, { env = { DENO_DIR = cache } }, function()
		M.cache_pending[ts] = nil
		M.cache_ongoing = M.cache_ongoing - 1
		for pending, _ in pairs(M.cache_pending) do
			M.cache_pending[pending] = nil
			M.cache(pending, bin, cache)
			return
		end
	end)
end

---Deno cache asynchronously on a directory
---
---See M.cache for the asynchronous behavior.
function M.cache_dir(dir, bin, cache)
	local cmd = { "fd", ".", "--type", "f", "-e", "ts" }
	vim.notify("deno cache " .. dir)
	return vim.system(cmd, { cwd = dir, text = true }, function(fd)
		if fd.stdout then
			for ts in fd.stdout:gmatch("[^\n]+") do
				M.cache(vim.fs.joinpath(dir, ts), bin, cache)
			end
		end
	end)
end

return M
