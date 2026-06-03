-- miner.lua
-- Simple branch miner for CC: Tweaked mining turtles.
-- Usage:
--   miner <mainTunnelLength> <branchLength>
-- Example:
--   miner 64 16

local mainLength = tonumber(({ ... })[1]) or 64
local branchLength = tonumber(({ ... })[2]) or 16

local wantedOres = {
	["minecraft:coal_ore"] = true,
	["minecraft:deepslate_coal_ore"] = true,

	["minecraft:diamond_ore"] = true,
	["minecraft:deepslate_diamond_ore"] = true,

	["minecraft:iron_ore"] = true,
	["minecraft:deepslate_iron_ore"] = true,

	["minecraft:gold_ore"] = true,
	["minecraft:deepslate_gold_ore"] = true,

	["minecraft:redstone_ore"] = true,
	["minecraft:deepslate_redstone_ore"] = true,

	["minecraft:lapis_ore"] = true,
	["minecraft:deepslate_lapis_ore"] = true,

	["minecraft:copper_ore"] = true,
	["minecraft:deepslate_copper_ore"] = true,

	["minecraft:emerald_ore"] = true,
	["minecraft:deepslate_emerald_ore"] = true,
}

local junk = {
	["minecraft:cobblestone"] = true,
	["minecraft:cobbled_deepslate"] = true,
	["minecraft:dirt"] = true,
	["minecraft:gravel"] = true,
	["minecraft:tuff"] = true,
	["minecraft:andesite"] = true,
	["minecraft:diorite"] = true,
	["minecraft:granite"] = true,
	["minecraft:netherrack"] = true,
}

local function refuelIfNeeded()
	if turtle.getFuelLevel() == "unlimited" then
		return true
	end

	if turtle.getFuelLevel() > 100 then
		return true
	end

	print("Fuel low. Trying to refuel...")

	for slot = 1, 16 do
		turtle.select(slot)
		local item = turtle.getItemDetail(slot)

		if item then
			turtle.refuel(1)

			if turtle.getFuelLevel() > 100 then
				print("Refueled. Fuel:", turtle.getFuelLevel())
				return true
			end
		end
	end

	print("No usable fuel found.")
	return false
end

local function isOre(block)
	return block and wantedOres[block.name] == true
end

local function inspectFront()
	local ok, block = turtle.inspect()
	return ok and block or nil
end

local function inspectUp()
	local ok, block = turtle.inspectUp()
	return ok and block or nil
end

local function inspectDown()
	local ok, block = turtle.inspectDown()
	return ok and block or nil
end

local function safeDig()
	while turtle.detect() do
		turtle.dig()
		sleep(0.1)
	end
end

local function safeDigUp()
	while turtle.detectUp() do
		turtle.digUp()
		sleep(0.1)
	end
end

local function safeDigDown()
	while turtle.detectDown() do
		turtle.digDown()
		sleep(0.1)
	end
end

local function forward()
	refuelIfNeeded()
	safeDig()

	while not turtle.forward() do
		turtle.attack()
		safeDig()
		sleep(0.1)
	end
end

local function back()
	refuelIfNeeded()

	while not turtle.back() do
		turtle.turnLeft()
		turtle.turnLeft()
		safeDig()
		turtle.turnLeft()
		turtle.turnLeft()
		sleep(0.1)
	end
end

local function turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
end

local function mineIfOreForward()
	local block = inspectFront()

	if isOre(block) then
		print("Mining ore:", block.name)
		safeDig()
		return true
	end

	return false
end

local function mineIfOreUp()
	local block = inspectUp()

	if isOre(block) then
		print("Mining ore:", block.name)
		safeDigUp()
		return true
	end

	return false
end

local function mineIfOreDown()
	local block = inspectDown()

	if isOre(block) then
		print("Mining ore:", block.name)
		safeDigDown()
		return true
	end

	return false
end

local function scanAround()
	-- Up/down
	mineIfOreUp()
	mineIfOreDown()

	-- Front + all four horizontal directions.
	for i = 1, 4 do
		mineIfOreForward()
		turtle.turnRight()
	end
end

local function dumpJunk()
	for slot = 1, 16 do
		turtle.select(slot)
		local item = turtle.getItemDetail(slot)

		if item and junk[item.name] then
			turtle.drop()
		end
	end

	turtle.select(1)
end

local function hasInventorySpace()
	for slot = 1, 16 do
		if turtle.getItemCount(slot) == 0 then
			return true
		end
	end

	return false
end

local function handleInventory()
	if hasInventorySpace() then
		return
	end

	print("Inventory full. Dumping junk...")
	dumpJunk()

	if not hasInventorySpace() then
		print("Still full. Place chest in front, then press Enter.")
		read()
		for slot = 1, 16 do
			turtle.select(slot)
			turtle.drop()
		end
		turtle.select(1)
	end
end

local function mineTunnel(length)
	for i = 1, length do
		handleInventory()
		scanAround()

		safeDigUp()
		safeDig()
		forward()

		print("Progress:", i, "/", length)
	end
end

local function mineBranch(length)
	mineTunnel(length)

	turnAround()

	for i = 1, length do
		forward()
	end

	turnAround()
end

print("Starting branch mine.")
print("Main tunnel:", mainLength)
print("Branch length:", branchLength)

refuelIfNeeded()

for step = 1, mainLength do
	handleInventory()
	scanAround()

	-- Every 4 blocks, mine left and right branches.
	if step % 4 == 0 then
		print("Mining left branch...")
		turtle.turnLeft()
		mineBranch(branchLength)

		print("Mining right branch...")
		turtle.turnRight()
		turtle.turnRight()
		mineBranch(branchLength)

		turtle.turnLeft()
	end

	safeDigUp()
	safeDig()
	forward()

	print("Main progress:", step, "/", mainLength)
end

print("Done.")
