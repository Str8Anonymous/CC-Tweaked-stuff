-- Inventory.lua

local Inventory = {}
Inventory.__index = Inventory

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

return Inventory
