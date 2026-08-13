local M = {}

local client_name = "denols-cache"
local cache_root = vim.fs.joinpath(vim.fn.stdpath("cache"), "deno", "modules")

---@param specifier string
---@return string?
local function cache_path(specifier)
	local scheme, path = specifier:match("^(https?)://([^?#]+)")
	if not scheme then
		return nil
	end
	return vim.fs.joinpath(cache_root, scheme, path)
end

---@param path string
---@param content string
local function write(path, content)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	local file, err = io.open(path, "wb")
	if not file then
		error(err)
	end
	file:write(content)
	file:close()
end

---@param entry table
---@return string
local function read_cache_entry(entry)
	local file, err = io.open(entry["local"], "rb")
	if not file then
		error(err)
	end
	local content = file:read(entry.size)
	file:close()
	if not content then
		error("failed to read " .. entry["local"])
	end
	return content
end

---@param url string
---@return string
local function materialize(url)
	local result = vim.system({ "deno", "info", "--quiet", "--json", "--no-config", "--no-lock", url }, {
		text = true,
	}):wait()
	if result.code ~= 0 then
		error(result.stderr ~= "" and result.stderr or ("failed to resolve " .. url))
	end

	local info = vim.json.decode(result.stdout)
	local target
	for _, entry in ipairs(info.modules or {}) do
		local path = entry["local"] and cache_path(entry.specifier)
		if path and entry.size then
			write(path, read_cache_entry(entry))
			if entry.specifier == url then
				target = path
			end
		end
	end
	if not target then
		error("Deno cache entry not found: " .. url)
	end

	local config = vim.fs.joinpath(cache_root, "deno.json")
	if not vim.uv.fs_stat(config) then
		write(config, "{}\n")
	end
	return target
end

---@param buf integer
local function start_client(buf)
	local client = vim.lsp.get_clients({ name = client_name })[1]
	if client then
		vim.lsp.buf_attach_client(buf, client.id)
		return
	end

	vim.lsp.start({
		name = client_name,
		cmd = { "deno", "lsp" },
		cmd_env = { NO_COLOR = true },
		root_dir = cache_root,
		settings = { deno = { enable = true } },
	}, {
		bufnr = buf,
		reuse_client = function(candidate)
			return candidate.name == client_name
		end,
	})
end

---@param uri string
---@return string?
function M.to_url(uri)
	local scheme, path = uri:match("^deno:/(https?)/(.*)$")
	if not scheme then
		return nil
	end
	return scheme .. "://" .. path
end

---@param buf integer
---@param uri string
local function redirect(buf, uri)
	local url = M.to_url(uri)
	if not url then
		vim.notify("Unsupported Deno URI: " .. uri, vim.log.levels.ERROR)
		return
	end

	local ok, target = pcall(materialize, url)
	if not ok then
		vim.notify(target, vim.log.levels.ERROR)
		return
	end

	local existing = vim.fn.bufnr(target)
	if existing > 0 and existing ~= buf then
		if vim.bo[existing].modified then
			vim.notify("Cannot redirect to modified buffer: " .. target, vim.log.levels.ERROR)
			return
		end
		vim.api.nvim_buf_delete(existing, { force = true })
	end

	local file = assert(io.open(target, "rb"))
	local content = file:read("*a")
	file:close()
	local has_eol = content:sub(-1) == "\n"
	local lines = vim.split(content, "\n", { plain = true })
	if has_eol then
		table.remove(lines)
	end

	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_name(buf, target)
	vim.bo[buf].buftype = ""
	vim.bo[buf].swapfile = false
	vim.bo[buf].modeline = false
	vim.bo[buf].endofline = has_eol
	vim.bo[buf].modified = false
	vim.bo[buf].readonly = true

	local filetype = vim.filetype.match({ filename = target })
	if filetype then
		vim.bo[buf].filetype = filetype
	end
	start_client(buf)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("atusy.lsp.deno", {})
	vim.api.nvim_create_autocmd("BufReadCmd", {
		group = group,
		pattern = "deno:/*",
		desc = "Redirect Deno URIs to a local module cache",
		callback = function(ctx)
			redirect(ctx.buf, ctx.match)
		end,
	})
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = vim.fs.joinpath(cache_root, "*"),
		desc = "Attach Deno LSP to cached remote modules",
		callback = function(ctx)
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(ctx.buf) then
					start_client(ctx.buf)
				end
			end)
		end,
	})
	vim.api.nvim_create_autocmd("LspAttach", {
		group = group,
		callback = function(ctx)
			local client = vim.lsp.get_client_by_id(ctx.data.client_id)
			local path = vim.api.nvim_buf_get_name(ctx.buf)
			if client and client.name == "kakehashi" and vim.startswith(path, cache_root) then
				vim.lsp.buf_detach_client(ctx.buf, client.id)
			end
		end,
	})
end

return M
