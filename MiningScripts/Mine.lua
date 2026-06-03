-- Mine.lua

local Mine = {}
Mine.__index = Mine

function Mine.new(context)
	local self = setmetatable({}, Mine)

	self.state = context.state
	self.movement = context.movement

	return self
end

function Mine:run()
	print("Mine running.")
	print("Mining behavior not built yet.")
end

return Mine
