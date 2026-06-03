-- startup.lua

print("Booting turtle...")

if fs.exists("Update.lua") then
	print("Updating scripts...")
	shell.run("Update")
else
	print("Update.lua missing.")
end

if fs.exists("Main.lua") then
	print("Running Main...")
	shell.run("Main")
else
	print("Main.lua missing.")
end
