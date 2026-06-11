-- Kakehashi-driven endwise recipe for nvim-insx, with a regex fallback.

---Resolve the closing keyword to insert at the cursor, or nil if none
---applies (including buffers without a kakehashi client).
---@return string?
local function detect_end_text()
	local ok, text = pcall(function()
		return require("kakehashi.extra.endwise").get()
	end)
	if ok then
		return text
	end
	return nil
end

---@return insx.RecipeSource
local function recipe()
	return {
		priority = 100, -- take precedence over the regex fallback and pair recipes
		enabled = function()
			return detect_end_text() ~= nil
		end,
		action = function(ctx)
			local end_text = detect_end_text()
			if not end_text then
				-- buffer changed since `enabled`; defer to the next recipe instead
				-- of swallowing the <CR>.
				return ctx.next()
			end
			local row, col = ctx.row(), ctx.col()
			ctx.send("<CR>" .. end_text)
			ctx.move(row, col)
			ctx.send("<CR>")
		end,
	}
end

return {
	setup = function()
		local insx = require("insx")
		-- primary: kakehashi-driven detection across every language whose
		-- endwise query the server can see.
		insx.add("<CR>", recipe())

		-- fallback: insx's built-in regex endwise for buffers without kakehashi.
		-- Lower priority, so it only fires when detection misses.
		local endwise = require("insx.recipe.endwise")
		insx.add(
			"<CR>",
			endwise({
				lua = endwise.builtin.lua,
				html = endwise.builtin.html,
			})
		)
	end,
}
