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
	package.loaded.Inventory = nil
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
		itemDetails = {},
		refuelSlots = {},
		dropCalls = 0,
		droppedItems = {},
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
		getItemDetail = function(slot)
			local name = turtleState.itemDetails[slot]
			if not name then
				return nil
			end

			return { name = name, count = turtleState.itemCounts[slot] or 0 }
		end,
		drop = function()
			local slot = turtleState.selectedSlot
			local count = turtleState.itemCounts[slot] or 0
			if count <= 0 then
				return false
			end

			turtleState.dropCalls = turtleState.dropCalls + 1
			turtleState.droppedItems[slot] = (turtleState.droppedItems[slot] or 0) + count
			turtleState.itemCounts[slot] = 0
			return true
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
	assertEqual(state.data.x, 1084)
	assertEqual(state.data.y, 63)
	assertEqual(state.data.z, -340)
	assertEqual(state.data.facing, 0)
	assertEqual(state.data.mineStartX, 1131)
	assertEqual(state.data.mineStartY, 16)
	assertEqual(state.data.mineStartZ, -342)
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
	assertEqual(state.data.x, 1084)
	assertEqual(state.data.y, 63)
	assertEqual(state.data.z, -340)
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
	state.data.x = 1131
	state.data.y = 16
	state.data.z = -342

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
	state.data.x = 1131
	state.data.y = 16
	state.data.z = -342
	state.data.facing = 1

	local movement = Movement.new(state)
	local mine = Mine.new({ state = state, movement = movement })
	local result = mine:run(3)

	assertEqual(result, "mining")
	assertEqual(state.data.stage, "mining")
	assertEqual(state.data.mineDistance, 3)
	assertEqual(state.data.y, 16)
	assertEqual(state.data.x, 1134)
	assertEqual(state.data.z, -342)
	assertEqual(turtleState.forwardCalls, 3)
	assertEqual(turtleState.digUpCalls, 3)
	assertEqual(turtleState.digDownCalls, 0)
	assertEqual(turtleState.digCalls, 6)
	assertEqual(state.data.facing, 1)
end)

test("inventory unload drops non-empty slots into chest behind and preserves facing", function()
	resetModules()
	local turtleState = installComputerCraftMocks()
	turtleState.itemCounts[1] = 12
	turtleState.itemCounts[5] = 64

	local State = require("State")
	local Movement = require("Movement")
	local Inventory = require("Inventory")
	local state = State.new()
	state.data.facing = 0

	local movement = Movement.new(state)
	local inventory = Inventory.new({ movement = movement })
	local unloaded = inventory:unloadBehind()

	assertEqual(unloaded, 76)
	assertEqual(turtleState.dropCalls, 2)
	assertEqual(turtleState.droppedItems[1], 12)
	assertEqual(turtleState.droppedItems[5], 64)
	assertEqual(turtleState.itemCounts[1], 0)
	assertEqual(turtleState.itemCounts[5], 0)
	assertEqual(state.data.facing, 0)
	assertEqual(turtleState.rightTurns, 4)
end)

test("inventory dropJunk drops common stone junk and keeps ores", function()
	resetModules()
	local turtleState = installComputerCraftMocks()
	turtleState.itemCounts[1] = 64
	turtleState.itemDetails[1] = "minecraft:cobblestone"
	turtleState.itemCounts[2] = 32
	turtleState.itemDetails[2] = "minecraft:cobbled_deepslate"
	turtleState.itemCounts[3] = 8
	turtleState.itemDetails[3] = "minecraft:raw_iron"
	turtleState.itemCounts[4] = 12
	turtleState.itemDetails[4] = "minecraft:coal"

	local State = require("State")
	local Movement = require("Movement")
	local Inventory = require("Inventory")
	local state = State.new()
	local movement = Movement.new(state)
	local inventory = Inventory.new({ movement = movement })
	local dropped = inventory:dropJunk()

	assertEqual(dropped, 96)
	assertEqual(turtleState.itemCounts[1], 0)
	assertEqual(turtleState.itemCounts[2], 0)
	assertEqual(turtleState.itemCounts[3], 8)
	assertEqual(turtleState.itemCounts[4], 12)
	assertEqual(turtleState.dropCalls, 2)
end)

test("mine run drops junk before deciding inventory is full", function()
	resetModules()
	local turtleState = installComputerCraftMocks()
	for slot = 1, 16 do
		turtleState.itemCounts[slot] = 64
		turtleState.itemDetails[slot] = "minecraft:cobblestone"
	end

	local State = require("State")
	local Movement = require("Movement")
	local Inventory = require("Inventory")
	local Mine = require("Mine")
	local state = State.new()
	state.data.stage = "mining"
	state.data.x = 1131
	state.data.y = 16
	state.data.z = -342
	state.data.facing = 1

	local movement = Movement.new(state)
	local inventory = Inventory.new({ movement = movement })
	local mine = Mine.new({ state = state, movement = movement, inventory = inventory })
	local result = mine:run(1)

	assertEqual(result, "mining")
	assertEqual(state.data.stage, "mining")
	assertEqual(state.data.mineDistance, 1)
	assertEqual(turtleState.dropCalls, 16)
	assertEqual(turtleState.forwardCalls, 1)
end)

test("mine run resumes from saved tunnel distance at stair bottom", function()
	resetModules()
	local turtleState = installComputerCraftMocks()

	local State = require("State")
	local Movement = require("Movement")
	local Mine = require("Mine")
	local state = State.new()
	state.data.stage = "mining"
	state.data.x = 1131
	state.data.y = 16
	state.data.z = -342
	state.data.facing = 1
	state.data.mineDistance = 3

	local movement = Movement.new(state)
	local mine = Mine.new({ state = state, movement = movement })
	local result = mine:run(1)

	assertEqual(result, "mining")
	assertEqual(state.data.x, 1135)
	assertEqual(state.data.y, 16)
	assertEqual(state.data.z, -342)
	assertEqual(state.data.mineDistance, 4)
	assertEqual(turtleState.forwardCalls, 4)
end)

test("returnHome climbs the staircase from the mining tunnel", function()
	resetModules()
	local turtleState = installComputerCraftMocks()

	local State = require("State")
	local Movement = require("Movement")
	local state = State.new()
	state.data.stage = "returning_home"
	state.data.x = 1135
	state.data.y = 16
	state.data.z = -342
	state.data.facing = 1
	state.data.mineDistance = 4

	local movement = Movement.new(state)
	movement:returnHome()

	assertEqual(state.data.stage, "at_base")
	assertEqual(state.data.x, 1084)
	assertEqual(state.data.y, 63)
	assertEqual(state.data.z, -340)
	assertEqual(state.data.facing, 0)
	assertEqual(state.data.mineDistance, 4)
	assertEqual(turtleState.upCalls, 47)
	assertEqual(turtleState.forwardCalls, 53)
end)

test("turtle start unloads inventory after returning home", function()
	resetModules()
	installComputerCraftMocks()

	local State = require("State")
	local TurtleStart = require("TurtleStart")
	local state = State.new()
	state.data.stage = "returning_home"
	state.data.x = 1084
	state.data.y = 63
	state.data.z = -340
	state.data.facing = 0

	local inventory = {
		calls = 0,
		unloadBehind = function(self)
			self.calls = self.calls + 1
			return 10
		end,
	}

	local app = TurtleStart.new({
		state = state,
		inventory = inventory,
	})
	local stage = app:start()

	assertEqual(stage, "at_base")
	assertEqual(inventory.calls, 1)
end)

test("turtle start makes a staircase from cave entrance before mining", function()
	resetModules()
	local turtleState = installComputerCraftMocks()

	local TurtleStart = require("TurtleStart")
	local app = TurtleStart.new()
	app.mine.maxStepsPerRun = 2
	app:start()

	assertEqual(app.state.data.stage, "mining")
	assertEqual(app.state.data.x, 1133)
	assertEqual(app.state.data.y, 16)
	assertEqual(app.state.data.z, -342)
	assertEqual(app.state.data.facing, 1)
	assertEqual(app.state.data.mineDistance, 2)
	assertEqual(turtleState.leftTurns, 4)
	assertEqual(turtleState.rightTurns, 5)
	assertEqual(turtleState.downCalls, 47)
	assertEqual(turtleState.forwardCalls, 51)
	assertEqual(turtleState.digCalls, 4)
	assertEqual(turtleState.digUpCalls, 2)
	assertEqual(turtleState.digDownCalls, 0)
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
