-- Reset.lua

print("WARNING This will delete all downloaded scripts and state files!")
print("Press Enter to confirm or any other key to cancel.")

local FILES_TO_IGNORE = {
	["startup.lua"] = true,
	["Update.lua"] = true,
	["Reset.lua"] = true,
}

local _, key = os.pullEvent("key")

if key ~= keys.enter then
	print("Reset canceled.")
	return
end

local allFiles = fs.list("")
local count = 0

for _, fileName in ipairs(allFiles) do
	-- The fs.isReadOnly check prevents the rom crash
	if not FILES_TO_IGNORE[fileName] and not fs.isReadOnly(fileName) then
		print("Deleting " .. fileName .. "...")
		fs.delete(fileName)
		count = count + 1
	end
end

print("Factory reset complete. Deleted " .. count .. " file(s).")

print("WOULD YOU LIKE TO REBOOT?")

local _, key = os.pullEvent("key")

if key then = keys.enter then
	print("Rebooting..")
	sleep(1.5)
	os.reboot()
	return
end