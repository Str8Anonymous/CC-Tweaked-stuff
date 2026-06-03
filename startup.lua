-- startup.lua

local STATE_FILE = "state.txt"

local function hasStarted()
	if not fs.exists(STATE_FILE) then
		return false
	end

	local file = fs.open(STATE_FILE, "r")
	local value = file.readAll()
	file.close()

	return value == "started"
end

local function markStarted()
	local file = fs.open(STATE_FILE, "w")
	file.write("started")
	file.close()
end

print("Booting turtle...")

-- Optional: update scripts from GitHub first.
if fs.exists("Update.lua") then
	print("Updating scripts...")
	shell.run("Update")
end

if not hasStarted() then
	print("First start detected. Running EnterStart...")
	shell.run("EnterStart")
	markStarted()
else
	print("Already started. Skipping EnterStart.")
end
