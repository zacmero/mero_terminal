local M = {}
local toggle = ya.sync(function(state)
	state.enabled = not state.enabled
	return state.enabled
end)

function M:entry()
	local enabled = toggle()
	ya.emit("linemode", { enabled and "size" or "none" })
end

return M
