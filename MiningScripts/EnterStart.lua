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
	self.movement:forwardMany(2)
	self.movement:turnRight()

	print("EnterStart finished.")
end

return EnterStart
