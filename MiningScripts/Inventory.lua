-- Inventory.lua

local Inventory = {}
Inventory.__index = Inventory

local JUNK_ITEMS = {
	["minecraft:stone"] = true,
	["minecraft:cobblestone"] = true,
	["minecraft:deepslate"] = true,
	["minecraft:cobbled_deepslate"] = true,
	["minecraft:dirt"] = true,
	["minecraft:grass_block"] = true,
	["minecraft:gravel"] = true,
	["minecraft:tuff"] = true,
	["minecraft:calcite"] = true,
	["minecraft:granite"] = true,
	["minecraft:diorite"] = true,
	["minecraft:andesite"] = true,
	["minecraft:sand"] = true,
	["minecraft:red_sand"] = true,
}

function Inventory.new(context)
	local self = setmetatable({}, Inventory)

	self.movement = context.movement

	return self
end

function Inventory:unloadBehind()
	print("Unloading inventory behind turtle.")

	local unloaded = 0

	self.movement:turnAround()

	for slot = 1, 16 do
		local count = turtle.getItemCount(slot)
		if count > 0 then
			turtle.select(slot)
			if turtle.drop() then
				unloaded = unloaded + count
			end
		end
	end

	self.movement:turnAround()

	print("Unloaded " .. unloaded .. " item(s).")
	return unloaded
end

function Inventory:_isJunk(slot)
	local detail = turtle.getItemDetail(slot)
	if not detail or not detail.name then
		return false
	end

	return JUNK_ITEMS[detail.name] == true
end

function Inventory:dropJunk()
	local dropped = 0

	for slot = 1, 16 do
		local count = turtle.getItemCount(slot)
		if count > 0 and self:_isJunk(slot) then
			turtle.select(slot)
			if turtle.drop() then
				dropped = dropped + count
			end
		end
	end

	if dropped > 0 then
		print("Dropped " .. dropped .. " junk item(s).")
	end

	return dropped
end

return Inventory
