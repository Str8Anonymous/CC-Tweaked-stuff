local OWNER = "Str8Anonymous"
local REPO = "CC-Tweaked-stuff"
local BRANCH = "main"
local FOLDER = "MiningScripts"

local function request(url)
	local response, err = http.get(url, {
		["User-Agent"] = "CC-Tweaked",
	})

	if not response then
		error("HTTP failed: " .. tostring(err), 0)
	end

	local body = response.readAll()
	response.close()

	return body
end

local function download(url, outputPath)
	local body = request(url)

	if fs.exists(outputPath) then
		fs.delete(outputPath)
	end

	local file = fs.open(outputPath, "w")
	file.write(body)
	file.close()
end

local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s"):format(OWNER, REPO, FOLDER, BRANCH)

print("Checking GitHub...")
local body = request(apiUrl)

local entries = textutils.unserializeJSON(body)
if type(entries) ~= "table" then
	error("GitHub did not return a file list", 0)
end

for _, entry in ipairs(entries) do
	if entry.type == "file" and entry.name:match("%.lua$") then
		print("Downloading " .. entry.name)
		download(entry.download_url, entry.name)
	end
end

print("Done.")
