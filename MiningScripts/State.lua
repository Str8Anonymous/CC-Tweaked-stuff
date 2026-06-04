-- State.lua

local MiningConfig = require("MiningConfig")

local State = {}
State.__index = State

local DEFAULT_DATA = {
	stage = "at_base",
	x = MiningConfig.baseX,
	y = MiningConfig.baseY,
	z = MiningConfig.baseZ,
	facing = MiningConfig.baseFacing,
	mineStartX = MiningConfig.mineStartX,
	mineStartY = MiningConfig.mineStartY,
	mineStartZ = MiningConfig.mineStartZ,
	mineY = MiningConfig.mineY,
	mineDistance = 0,
}

function State.new(path)
	local self = setmetatable({}, State)
	self.path = path or "state.json"
	self.data = self:load()
	return self
end

function State:_copyDefault()
	local toReturn = {}
	for key, value in pairs(DEFAULT_DATA) do
		toReturn[key] = value
	end
	return toReturn
end

function State:_withDefaults(data)
	local withDefaults = self:_copyDefault()

	if type(data) == "table" then
		for key, value in pairs(data) do
			withDefaults[key] = value
		end
	end

	return withDefaults
end

function State:load()
	if not fs.exists(self.path) then
		return self:_copyDefault()
	end

	local file = fs.open(self.path, "r")
	local contents = file.readAll()
	file.close()

	if contents == nil or contents == "" then
		return self:_copyDefault()
	end

	local data = textutils.unserializeJSON(contents)
	if type(data) ~= "table" then
		return self:_copyDefault()
	end

	return self:_withDefaults(data)
end

function State:save()
	local file = fs.open(self.path, "w")
	file.write(textutils.serializeJSON(self.data))
	file.close()
end

function State:getStage()
	return self.data.stage
end

function State:setStage(stage)
	self.data.stage = stage
	self:save()
	return stage
end

function State:reset()
	self.data = self:_copyDefault()
	self:save()
end

return State
