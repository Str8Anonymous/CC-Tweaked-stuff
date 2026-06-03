print("WARNING: This will delete all local scripts and state files!")
print("Press Enter to confirm, or any other key to cancel.")

local _, key = os.pullEvent("key")
if key ~= keys.enter then
	print("Reset canceled.")
	return
end

-- List of all files to delete
local filesToDelete = {
	"state.json",
	"Main.lua",
	"TurtleStart.lua",
	"Movement.lua",
	"State.lua",
	"EnterStart.lua",
	"Mine.lua",
	"Update.lua",
}

local count = 0

for _, fileName in ipairs(filesToDelete) do
	if fs.exists(fileName) then
		print("Deleting " .. fileName .. "...")
		fs.delete(fileName)
		count = count + 1
	end
end

print("Factory reset complete. Deleted " .. count .. " file(s).")
print("Rebooting turtle...")
sleep(1.5)
os.reboot()
