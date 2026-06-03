-- Movement.lua

local Movement = {}
Movement.__index = Movement

function Movement.new()
	local self = setmetatable({}, Movement)

	self.minFuel = 20

	return self
end

function Movement:refuelIfNeeded(minFuel)
	minFuel = minFuel or self.minFuel

	if turtle.getFuelLevel() == "unlimited" then
		return true
	end

	if turtle.getFuelLevel() >= minFuel then
		return true
	end

	print("Low fuel. Trying to refuel...")

	for slot = 1, 16 do
		turtle.select(slot)

		if turtle.refuel(0) then
			turtle.refuel(1)

			if turtle.getFuelLevel() >= minFuel then
				print("Fuel: " .. turtle.getFuelLevel())
				return true
			end
		end
	end

	error("Not enough fuel", 0)
end

function Movement:_digForward()
	while turtle.detect() do
		local ok, err = turtle.dig()
		if not ok then
			print("Dig failed: " .. tostring(err))
			sleep(0.5)
		else
			sleep(0.2)
		end
	end
end

function Movement:forward()
	self:refuelIfNeeded()

	while not turtle.forward() do
		self:_digForward()
		sleep(0.2)
	end

	return true
end

function Movement:forwardMany(amount)
	for i = 1, amount do
		self:forward()
	end
end

function Movement:turnLeft()
	turtle.turnLeft()
end

function Movement:turnRight()
	turtle.turnRight()
end

function Movement:turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
end

return Movement
