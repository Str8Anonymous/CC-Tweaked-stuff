local OWNER = "Str8Anonymous"
local REPO = "CC-Tweaked-stuff"
local BRANCH = "main"
local FOLDER = "MiningScripts"

local function request(url, customHeaders)
	local headers = {
		["User-Agent"] = "CC-Tweaked",
		["Cache-Control"] = "no-cache",
	}

	if customHeaders then
		for k, v in pairs(customHeaders) do
			headers[k] = v
		end
	end

	local response, err = http.get(url, headers)

	if not response then
		error("HTTP failed " .. tostring(err), 0)
	end

	local body = response.readAll()
	response.close()

	return body
end

local function download(url, outputPath)
	local cacheBuster = tostring(os.epoch("utc"))

	local sep = "?"
	if url:find("?") then
		sep = "&"
	end

	local finalUrl = url .. sep .. "t=" .. cacheBuster
	print("URL " .. finalUrl)

	local headers = {
		["Accept"] = "application/vnd.github.v3.raw",
	}

	local body = request(finalUrl, headers)

	if fs.exists(outputPath) then
		fs.delete(outputPath)
	end

	local file = fs.open(outputPath, "w")
	file.write(body)
	file.close()
end

local apiUrl = ("https://api.github.com/repos/%s/%s/contents/%s?ref=%s&t=%s"):format(
	OWNER,
	REPO,
	FOLDER,
	BRANCH,
	tostring(os.epoch("utc"))
)

print("Checking GitHub...")
local body = request(apiUrl)

local entries = textutils.unserializeJSON(body)
if type(entries) ~= "table" then
	error("GitHub did not return a file list", 0)
end

local count = 0

for _, entry in ipairs(entries) do
	if entry.type == "file" and entry.name:match("%.lua$") then
		print("Downloading " .. entry.name)
		download(entry.url, entry.name)
		count = count + 1
	end
end

print("Done. Downloaded " .. count .. " file(s).")
