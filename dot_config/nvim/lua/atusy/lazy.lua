local M = {}

function M.install(lazypath)
  local cmd = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  return cmd:wait()
end

function M.reload()
  local function try(...)
    local ok, res = pcall(...)
    if not ok then
      vim.notify(res, vim.log.levels.ERROR)
    end
    return ok
  end

  local loaded = vim.tbl_keys(package.loaded)
  for _, p in pairs(loaded) do
    if p == "atusy" or vim.startswith(p, "atusy.") then
      require("atusy.utils").require(p)
    end
  end

  local configurable
  for _, p in pairs(loaded) do
    if p == "plugins" or vim.startswith(p, "plugins.") then
      for _, d in pairs(require("atusy.utils").require(p)) do
        if type(d) == "table" and d.enabled ~= false and d.cond ~= false then
          local pname = d[1]:gsub(".*/", "")
          require("lazy").load({ plugins = pname })
          if d.init then
            configurable = try(d.init)
            if not configurable then
              vim.notify("FAILED: " .. d .. ".init()", vim.log.levels.ERROR)
            end
          end
          if d.config and configurable then
            if not try(d.config) then
              vim.notify("FAILED: " .. d .. ".config()", vim.log.levels.ERROR)
            end
          end
        end
      end
    end
  end
end

return M
