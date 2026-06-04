package.path = "MiningScripts/?.lua;" .. package.path

local tests = {}

local function test(name, fn)
	tests[#tests + 1] = { name = name, fn = fn }
end

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		error((message or "assertEqual failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function assertTrue(value, message)
	if not value then
		error(message or "assertTrue failed", 2)
	end
end

local function resetModules()
	package.loaded.MiningConfig = nil
	package.loaded.State = nil
	package.loaded.Movement = nil
	package.loaded.Mine = nil
	package.loaded.TurtleStart = nil
end

local function installComputerCraftMocks()
	local files = {}

	fs = {
		exists = function(path)
			return files[path] ~= nil
		end,
		open = function(path, mode)
			if mode == "r" then
				local contents = files[path]
				return {
					readAll = function()
						return contents
					end,
					close = function() end,
				}
			end

			local buffer = {}
			return {
				write = function(value)
					buffer[#buffer + 1] = tostring(value)
				end,
				close = function()
					files[path] = table.concat(buffer)
				end,
			}
		end,
	}

	textutils = {
		serializeJSON = function(data)
			local parts = {}
			for key, value in pairs(data) do
				local encoded
				if type(value) == "string" then
					encoded = string.format("%q", value)
				else
					encoded = tostring(value)
				end
				parts[#parts + 1] = string.format("%q:%s", key, encoded)
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end,
		unserializeJSON = function()
			return nil
		end,
	}

	sleep = function() end

	local turtleState = {
		fuel = 1000,
		forwardCalls = 0,
		upCalls = 0,
		downCalls = 0,
		digCalls = 0,
		digUpCalls = 0,
		digDownCalls = 0,
		leftTurns = 0,
		rightTurns = 0,
		itemCounts = {},
		refuelSlots = {},
	}

	turtle = {
		getFuelLevel = function()
			return turtleState.fuel
		end,
		select = function(slot)
			turtleState.selectedSlot = slot
			return true
		end,
		refuel = function(amount)
			if turtleState.refuelSlots[turtleState.selectedSlot] then
				if amount > 0 then
					turtleState.fuel = turtleState.fuel + (80 * amount)
				end
				return true
			end
			return false
		end,
		detect = function()
			return false
		end,
		detectUp = function()
			return false
		end,
		detectDown = function()
			return false
		end,
		dig = function()
			turtleState.digCalls = turtleState.digCalls + 1
			return true
		end,
		digUp = function()
			turtleState.digUpCalls = turtleState.digUpCalls + 1
			return true
		end,
		digDown = function()
			turtleState.digDownCalls = turtleState.digDownCalls + 1
			return true
		end,
		forward = function()
			turtleState.forwardCalls = turtleState.forwardCalls + 1
			if turtleState.fuel ~= "unlimited" then
				turtleState.fuel = turtleState.fuel - 1
			end
			return true
		end,
		up = function()
			turtleState.upCalls = turtleState.upCalls + 1
			if turtleState.fuel ~= "unlimited" then
				turtleState.fuel = turtleState.fuel - 1
			end
			return true
		end,
		down = function()
			turtleState.downCalls = turtleState.downCalls + 1
			if turtleState.fuel ~= "unlimited" then
				turtleState.fuel = turtleState.fuel - 1
			end
			return true
		end,
		turnLeft = function()
			turtleState.leftTurns = turtleState.leftTurns + 1
			return true
		end,
		turnRight = function()
			turtleState.rightTurns = turtleState.rightTurns + 1
			return true
		end,
		getItemCount = function(slot)
			return turtleState.itemCounts[slot] or 0
		end,
	}

	return turtleState
end

test("state defaults include base, mine start, target Y, and mining progress", function()
	resetModules()
	installComputerCraftMocks()

	local State = require("State")
	local state = State.new()

	assertEqual(state.data.stage, "at_base")
	assertEqual(state.data.x, 1085)
	assertEqual(state.data.y, 64)
	assertEqual(state.data.z, -339)
	assertEqual(state.data.facing, 0)
	assertEqual(state.data.mineStartX, 1084)
	assertEqual(state.data.mineStartY, 64)
	assertEqual(state.data.mineStartZ, -338)
	assertEqual(state.data.mineY, 16)
	assertEqual(state.data.mineDistance, 0)
end)

test("returnHome preserves mining progress while resetting position and stage", function()
	resetModules()
	installComputerCraftMocks()

	local State = require("State")
	local Movement = require("Movement")
	local state = State.new()
	state.data.stage = "returning_home"
	state.data.x = 1084
	state.data.y = 16
	state.data.z = -350
	state.data.facing = 0
	state.data.mineDistance = 12

	local movement = Movement.new(state)
	movement:returnHome()

	assertEqual(state.data.stage, "at_base")
	assertEqual(state.data.x, 1085)
	assertEqual(state.data.y, 64)
	assertEqual(state.data.z, -339)
	assertEqual(state.data.facing, 0)
	assertEqual(state.data.mineDistance, 12)
end)

test("mine run returns immediately when inventory is full", function()
	resetModules()
	local turtleState = installComputerCraftMocks()
	for slot = 1, 16 do
		turtleState.itemCounts[slot] = 64
	end

	local State = require("State")
	local Movement = require("Movement")
	local Mine = require("Mine")
	local state = State.new()
	state.data.stage = "mining"
	state.data.x = 1084
	state.data.y = 16
	state.data.z = -338

	local movement = Movement.new(state)
	local mine = Mine.new({ state = state, movement = movement })
	local result = mine:run(5)

	assertEqual(result, "returning_home")
	assertEqual(state.data.stage, "returning_home")
	assertEqual(state.data.mineDistance, 0)
	assertEqual(turtleState.forwardCalls, 0)
end)

test("mine run digs at Y 16 and tracks tunnel distance", function()
	resetModules()
	local turtleState = installComputerCraftMocks()

	local State = require("State")
	local Movement = require("Movement")
	local Mine = require("Mine")
	local state = State.new()
	state.data.stage = "mining"
	state.data.x = 1084
	state.data.y = 16
	state.data.z = -338
	state.data.facing = 0

	local movement = Movement.new(state)
	local mine = Mine.new({ state = state, movement = movement })
	local result = mine:run(3)

	assertEqual(result, "mining")
	assertEqual(state.data.stage, "mining")
	assertEqual(state.data.mineDistance, 3)
	assertEqual(state.data.y, 16)
	assertEqual(state.data.z, -341)
	assertEqual(turtleState.forwardCalls, 3)
	assertEqual(turtleState.digUpCalls, 3)
	assertEqual(turtleState.digDownCalls, 3)
end)

test("turtle start routes from base to Y16 mine and starts mining", function()
	resetModules()
	local turtleState = installComputerCraftMocks()

	local TurtleStart = require("TurtleStart")
	local app = TurtleStart.new()
	app.mine.maxStepsPerRun = 2
	app:start()

	assertEqual(app.state.data.stage, "mining")
	assertEqual(app.state.data.x, 1084)
	assertEqual(app.state.data.y, 16)
	assertEqual(app.state.data.z, -340)
	assertEqual(app.state.data.mineDistance, 2)
	assertTrue(turtleState.downCalls >= 48, "expected turtle to dig down from Y64 to Y16")
end)

local failures = 0

for _, current in ipairs(tests) do
	local ok, err = pcall(current.fn)
	if ok then
		print("PASS " .. current.name)
	else
		failures = failures + 1
		print("FAIL " .. current.name)
		print(err)
	end
end

if failures > 0 then
	error(tostring(failures) .. " test(s) failed", 0)
end

print("All " .. tostring(#tests) .. " tests passed")
