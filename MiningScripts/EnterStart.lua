-- EnterStart.lua

local function forward()
	while turtle.detect() do
		turtle.dig()
		sleep(0.1)
	end

	while not turtle.forward() do
		turtle.attack()
		sleep(0.1)
	end
end

print("Moving from spawn to mine entrance...")

for i = 1, 20 do
	forward()
end

turtle.turnRight()

for i = 1, 10 do
	forward()
end

print("Reached mine entrance.")
