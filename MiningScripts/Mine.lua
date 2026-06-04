-- Mine.lua

local MiningConfig = require("MiningConfig")

local Mine = {}
Mine.__index = Mine

function Mine.new(context)
	local self = setmetatable({}, Mine)

	self.state = context.state
	self.movement = context.movement
	self.maxStepsPerRun = context.maxStepsPerRun

	return self
end

function Mine:_isInventoryFull()
	for slot = 1, 16 do
		if turtle.getItemCount(slot) == 0 then
			return false
		end
	end

	return true
end

function Mine:_getReturnFuelRequired()
	return self.movement:getDistanceHome() + MiningConfig.returnFuelBuffer
end

function Mine:_getReturnReason()
	if self:_isInventoryFull() then
		return "inventory_full"
	end

	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel ~= "unlimited" and fuelLevel <= self:_getReturnFuelRequired() then
		return "low_fuel"
	end

	return nil
end

function Mine:_returnHome(reason)
	print("Returning home: " .. reason)
	self.state.data.returnReason = reason
	self.state:setStage("returning_home")
	return "returning_home"
end

function Mine:_isAtMineStart()
	return self.state.data.x == MiningConfig.mineStartX
		and self.state.data.y == MiningConfig.mineY
		and self.state.data.z == MiningConfig.mineStartZ
end

function Mine:_moveToTunnelEnd()
	self.movement:turnTo(MiningConfig.mineFacing)

	if not self:_isAtMineStart() then
		return
	end

	for _ = 1, (self.state.data.mineDistance or 0) do
		self.movement:forward()
	end
end

function Mine:_digAround()
	turtle.digUp()
	turtle.digDown()
end

function Mine:_mineOneStep()
	self.movement:turnTo(MiningConfig.mineFacing)
	self:_digAround()
	self.movement:forward()

	self.state.data.mineDistance = (self.state.data.mineDistance or 0) + 1
	self.state:save()
end

function Mine:run(maxSteps)
	print("Mine running.")

	self.state:setStage("mining")
	self:_moveToTunnelEnd()

	local steps = 0
	local limit = maxSteps or self.maxStepsPerRun

	while limit == nil or steps < limit do
		local returnReason = self:_getReturnReason()
		if returnReason then
			return self:_returnHome(returnReason)
		end

		self:_mineOneStep()
		steps = steps + 1
	end

	return "mining"
end

return Mine
