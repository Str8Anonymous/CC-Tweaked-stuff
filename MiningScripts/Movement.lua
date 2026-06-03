-- Movement.lua

local Movement = {}
Movement.__index = Movement

function Movement.new(state)
	local self = setmetatable({}, Movement)
	self.minFuel = 20
	self.state = state
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
				print("Fuel " .. turtle.getFuelLevel())
				return true
			end
		end
	end

	error("Not enough fuel", 0)
end

function Movement:_changeY(amount)
	self.state.data.y = (self.state.data.y or 0) + amount
	self.state:save()
	print("Current Y " .. self.state.data.y)
end

function Movement:_digForward()
	while turtle.detect() do
		local ok, err = turtle.dig()
		if not ok then
			print("Dig failed " .. tostring(err))
			sleep(0.5)
		else
			sleep(0.2)
		end
	end
end

function Movement:_digUp()
	while turtle.detectUp() do
		local ok, err = turtle.digUp()
		if not ok then
			print("Dig up failed " .. tostring(err))
			sleep(0.5)
		else
			sleep(0.2)
		end
	end
end

function Movement:_digDown()
	while turtle.detectDown() do
		local ok, err = turtle.digDown()
		if not ok then
			print("Dig down failed " .. tostring(err))
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

	-- This tracks the exact coordinates instead of just pushing a move string
	local f = self.state.data.facing or 0
	if f == 0 then
		self.state.data.z = self.state.data.z - 1
	elseif f == 1 then
		self.state.data.x = self.state.data.x + 1
	elseif f == 2 then
		self.state.data.z = self.state.data.z + 1
	elseif f == 3 then
		self.state.data.x = self.state.data.x - 1
	end

	self.state:save()
	return true
end

function Movement:up()
	self:refuelIfNeeded()
	while not turtle.up() do
		self:_digUp()
		sleep(0.2)
	end
	self:_changeY(1)
	return true
end

function Movement:down()
	self:refuelIfNeeded()
	while not turtle.down() do
		self:_digDown()
		sleep(0.2)
	end
	self:_changeY(-1)
	return true
end

function Movement:forwardMany(amount)
	for i = 1, amount do
		self:forward()
	end
end

function Movement:upMany(amount)
	for i = 1, amount do
		self:up()
	end
end

function Movement:downMany(amount)
	for i = 1, amount do
		self:down()
	end
end

function Movement:turnLeft()
	turtle.turnLeft()
	self.state.data.facing = (self.state.data.facing - 1) % 4
	self.state:save()
end

function Movement:turnRight()
	turtle.turnRight()
	self.state.data.facing = (self.state.data.facing + 1) % 4
	self.state:save()
end

function Movement:turnAround()
	self:turnRight()
	self:turnRight()
end

function Movement:turnTo(targetFacing)
	local current = self.state.data.facing or 0
	if current == targetFacing then
		return
	end

	local diff = (targetFacing - current) % 4
	if diff == 1 then
		self:turnRight()
	elseif diff == 3 then
		self:turnLeft()
	else
		self:turnAround()
	end
end

function Movement:gotoY(targetY)
	while self.state.data.y < targetY do
		self:up()
	end
	while self.state.data.y > targetY do
		self:down()
	end
end

function Movement:gotoX(targetX)
	if self.state.data.x < targetX then
		self:turnTo(1)
	elseif self.state.data.x > targetX then
		self:turnTo(3)
	end

	while self.state.data.x ~= targetX do
		self:forward()
	end
end

function Movement:gotoZ(targetZ)
	if self.state.data.z < targetZ then
		self:turnTo(2)
	elseif self.state.data.z > targetZ then
		self:turnTo(0)
	end

	while self.state.data.z ~= targetZ do
		self:forward()
	end
end

function Movement:returnHome()
	print("Calculating fast route home...")

	-- Go up to starting Y so we do not hit caves
	self:gotoY(64)

	-- Travel X and Z
	self:gotoX(1085)
	self:gotoZ(-339)

	-- Face forward again
	self:turnTo(0)

	print("Arrived home!")

	print("Wiping memory to become a fresh spawn...")
	self.state:reset()
end

return Movement
