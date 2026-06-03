-- Movement.lua

local Movement = {}
Movement.__index = Movement

-- We now pass the state instance in here
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
				print("Fuel: " .. turtle.getFuelLevel())
				return true
			end
		end
	end

	error("Not enough fuel", 0)
end

-- Fixed this function so it updates the correct instance
function Movement:_changeY(amount)
	self.state.data.y = (self.state.data.y or 0) + amount
	self.state:save()
	print("Current Y: " .. self.state.data.y)
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

function Movement:_digUp()
	while turtle.detectUp() do
		local ok, err = turtle.digUp()
		if not ok then
			print("Dig up failed: " .. tostring(err))
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
			print("Dig down failed: " .. tostring(err))
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
	self.state:pushMove("forward")
	return true
end

function Movement:up()
	self:refuelIfNeeded()
	while not turtle.up() do
		self:_digUp()
		sleep(0.2)
	end
	self:_changeY(1)
	self.state:pushMove("up")
	return true
end

function Movement:down()
	self:refuelIfNeeded()
	while not turtle.down() do
		self:_digDown()
		sleep(0.2)
	end
	self:_changeY(-1)
	self.state:pushMove("down")
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
	self.state:pushMove("turnLeft")
end

function Movement:turnRight()
	turtle.turnRight()
	self.state:pushMove("turnRight")
end

function Movement:turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
	self.state:pushMove("turnAround")
end

-- New function to retrace steps
function Movement:returnHome()
	print("Returning home...")
	local lastMove = self.state:popMove()

	while lastMove do
		if lastMove == "forward" then
			turtle.back()
		elseif lastMove == "up" then
			self:refuelIfNeeded()
			while not turtle.down() do
				self:_digDown()
				sleep(0.2)
			end
			self:_changeY(-1)
		elseif lastMove == "down" then
			self:refuelIfNeeded()
			while not turtle.up() do
				self:_digUp()
				sleep(0.2)
			end
			self:_changeY(1)
		elseif lastMove == "turnLeft" then
			turtle.turnRight()
		elseif lastMove == "turnRight" then
			turtle.turnLeft()
		elseif lastMove == "turnAround" then
			turtle.turnLeft()
			turtle.turnLeft()
		end

		lastMove = self.state:popMove()
	end

	print("Arrived home!")
end

return Movement
