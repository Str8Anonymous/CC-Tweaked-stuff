-- EnterStart.lua

local EnterStart = {}
EnterStart.__index = EnterStart

function EnterStart.new(context)
	local self = setmetatable({}, EnterStart)

	self.state = context.state
	self.movement = context.movement

	return self
end

function EnterStart:run()
	print("EnterStart running.")

	-- Example path:
	-- self.movement:forwardMany(3)
	-- self.movement:turnRight()
	-- self.movement:forwardMany(5)

	print("EnterStart finished.")
end

return EnterStart
