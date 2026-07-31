local configured

package.preload["fyler"] = function()
	return {
		setup = function(config)
			configured = config
		end,
	}
end

package.preload["plugins.fyler.mappings"] = function()
	return {}
end

local plugin = dofile("dot_config/nvim/lua/plugins/fyler/init.lua")[1]
plugin.config()

local replace = configured.kind_presets.replace
assert(
	replace.win_opts and replace.win_opts.winfixwidth == false,
	"the Fyler window width must remain adjustable"
)
