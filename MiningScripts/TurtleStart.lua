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
	self.movement = Movement.new()

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
		stage = self.state:setStage("at_base")
	end

	print("Stage: " .. stage)

	if stage == "at_base" then
		self.enterStart:run()

		stage = self.state:setStage("at_cave_start")
	end

	if stage == "at_cave_start" then
		self.mine:run()
	else
		error("Unknown stage: " .. tostring(stage), 0)
	end
end

return TurtleStart
