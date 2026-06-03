-- State.lua

local State = {}

local STATE_FILE = "state.json"

local DEFAULT_STATE = {
	stage = "at_base",
}

local function copyDefault()
	return {
		stage = DEFAULT_STATE.stage,
	}
end

function State.load()
	if not fs.exists(STATE_FILE) then
		return copyDefault()
	end

	local file = fs.open(STATE_FILE, "r")
	local contents = file.readAll()
	file.close()

	if contents == nil or contents == "" then
		return copyDefault()
	end

	local data = textutils.unserializeJSON(contents)
	if type(data) ~= "table" then
		return copyDefault()
	end

	if type(data.stage) ~= "string" then
		data.stage = DEFAULT_STATE.stage
	end

	return data
end

function State.save(data)
	local file = fs.open(STATE_FILE, "w")
	file.write(textutils.serializeJSON(data))
	file.close()
end

function State.getStage()
	local data = State.load()
	return data.stage
end

function State.setStage(stage)
	local data = State.load()
	data.stage = stage
	State.save(data)
end

function State.reset()
	State.save(copyDefault())
end

return State
