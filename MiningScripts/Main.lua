-- Main.lua

local State = require("State")

print("Main started.")

local stage = State.getStage()
print("Stage: " .. stage)

if stage == "at_base" then
	if not fs.exists("EnterStart.lua") then
		error("EnterStart.lua missing", 0)
	end

	print("Running EnterStart...")

	local ok = shell.run("EnterStart")
	if not ok then
		error("EnterStart failed", 0)
	end

	State.setStage("at_cave_start")
	print("Stage set to at_cave_start.")
end

stage = State.getStage()

if stage == "at_cave_start" then
	if fs.exists("Mine.lua") then
		print("Running Mine...")
		shell.run("Mine")
	else
		print("Mine.lua missing. Stopping at cave start.")
	end
else
	error("Unknown stage: " .. tostring(stage), 0)
end
