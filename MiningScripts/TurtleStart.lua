-- TurtleStart.lua

local State = require("State")
local Movement = require("Movement")
local EnterStart = require("EnterStart")
local Mine = require("Mine")

local TurtleStart = {}
TurtleStart.__index = TurtleStart

local DEBUG_MODE = true

function TurtleStart.new()
	local self = setmetatable({}, TurtleStart)

	self.state = State.new()
	self.state.data.x = 1085
	self.state.data.y = 64
	self.state.data.z = -339

	-- Pass the state instance to movement
	self.movement = Movement.new(self.state)

	self.enterStart = EnterStart.new({
		state = self.state,
		movement = self.movement,
	})

	self.mine = Mine.new({
		state = self.state,
		movement = self.movement,
	})

	return self
end

function TurtleStart:start()
	print("TurtleStart started.")

	local stage = self.state:getStage()

	if DEBUG_MODE then
		self.movement:turnRight()
		self.movement:forwardMany(2)
		self.movement:turnAround()
	end

	print("Stage " .. stage)

	if stage == "at_base" then
		self.enterStart:run()
		print("at cave enterance lets go back home")
		self.movement:returnHome()
	end
end

return TurtleStart
