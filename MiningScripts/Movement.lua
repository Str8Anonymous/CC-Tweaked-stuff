-- Movement.lua

local Movement = {}

local MIN_FUEL = 20

local function tryDig()
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

local function tryDigUp()
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

local function tryDigDown()
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

function Movement.refuelIfNeeded(minFuel)
	minFuel = minFuel or MIN_FUEL

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

	return false
end

function Movement.forward()
	Movement.refuelIfNeeded()

	while not turtle.forward() do
		tryDig()

		local ok, err = turtle.forward()
		if ok then
			return true
		end

		print("Forward blocked: " .. tostring(err))
		sleep(0.5)
	end

	return true
end

function Movement.up()
	Movement.refuelIfNeeded()

	while not turtle.up() do
		tryDigUp()

		local ok, err = turtle.up()
		if ok then
			return true
		end

		print("Up blocked: " .. tostring(err))
		sleep(0.5)
	end

	return true
end

function Movement.down()
	Movement.refuelIfNeeded()

	while not turtle.down() do
		tryDigDown()

		local ok, err = turtle.down()
		if ok then
			return true
		end

		print("Down blocked: " .. tostring(err))
		sleep(0.5)
	end

	return true
end

function Movement.back()
	Movement.refuelIfNeeded()

	while not turtle.back() do
		print("Back blocked.")
		sleep(0.5)
	end

	return true
end

function Movement.turnLeft()
	turtle.turnLeft()
	return true
end

function Movement.turnRight()
	turtle.turnRight()
	return true
end

function Movement.turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
	return true
end

function Movement.forwardMany(amount)
	for i = 1, amount do
		Movement.forward()
	end
end

function Movement.upMany(amount)
	for i = 1, amount do
		Movement.up()
	end
end

function Movement.downMany(amount)
	for i = 1, amount do
		Movement.down()
	end
end

return Movement
