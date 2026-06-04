-- TurtleStart.lua

local MiningConfig = require("MiningConfig")
local State = require("State")
local Movement = require("Movement")
local EnterStart = require("EnterStart")
local Mine = require("Mine")
local Inventory = require("Inventory")

local TurtleStart = {}
TurtleStart.__index = TurtleStart

function TurtleStart.new(context)
	context = context or {}

	local self = setmetatable({}, TurtleStart)

	self.state = context.state or State.new()

	-- Pass the state instance to movement
	self.movement = context.movement or Movement.new(self.state)

	self.enterStart = context.enterStart or EnterStart.new({
		state = self.state,
		movement = self.movement,
	})

	self.mine = context.mine or Mine.new({
		state = self.state,
		movement = self.movement,
	})

	self.inventory = context.inventory or Inventory.new({
		movement = self.movement,
	})

	return self
end

function TurtleStart:_goToMineStart()
	print("Going to mine start.")
	self.movement:gotoY(MiningConfig.caveEntranceY)
	self.movement:gotoX(MiningConfig.caveEntranceX)
	self.movement:gotoZ(MiningConfig.caveEntranceZ)
	self.movement:turnTo(MiningConfig.mineFacing)
end

function TurtleStart:_digDownToMineLevel()
	print("Digging down to mine level.")
	self:_goToMineStart()
	self.movement:stairDownTo(MiningConfig.mineY, MiningConfig.mineFacing)
	self.movement:turnTo(MiningConfig.mineFacing)
end

function TurtleStart:start()
	print("TurtleStart started.")

	local stage = self.state:getStage()

	if stage == "at_base" then
		print("Currently at base. Heading to mine.")
		stage = self.state:setStage("travel_to_mine")
	end

	if stage == "travel_to_mine" then
		self:_goToMineStart()
		stage = self.state:setStage("digging_down")
	end

	if stage == "digging_down" then
		self:_digDownToMineLevel()
		stage = self.state:setStage("mining")
	end

	if stage == "mining" then
		self.mine:run()
		stage = self.state:getStage()
	end

	if stage == "returning_home" then
		self.movement:returnHome()
		self.inventory:unloadBehind()
		stage = self.state:getStage()
	end

	return stage
end

return TurtleStart
