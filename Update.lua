local files = {
	{
		url = "https://raw.githubusercontent.com/YourUsername/cc-turtle-scripts/main/Mine.lua",
		name = "Mine.lua",
	},
	{
		url = "https://raw.githubusercontent.com/YourUsername/cc-turtle-scripts/main/SetupMine.lua",
		name = "SetupMine.lua",
	},
}

for _, file in ipairs(files) do
	if fs.exists(file.name) then
		fs.delete(file.name)
	end

	print("Downloading " .. file.name)
	shell.run("wget", file.url, file.name)
end

print("Done.")
