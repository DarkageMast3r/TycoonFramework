--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local common = replicatedStorage.Common
local replication = require(common.Replication)
local position = require(common.Data.Position)

local schemas: {
	[RemoteEvent]: {
		[(...any) -> ()]: {replication.argument_type}
	}
} = {}


local function scheme_matches(scheme: {replication.argument_type}, ...)
	local passed_scheme = {...}
	if #scheme ~= #passed_scheme then
		return false
	end
	local matches = true
	for i, t in scheme do
		local value = passed_scheme[i]
		if t == "Player" then
			matches = matches and typeof(value) == "Instance" and value:IsA("Player")
		elseif t == "number" then
			matches = matches and typeof(value) == "number"
		elseif t == "string" then
			matches = matches and typeof(value) == "string"
		elseif t == "position" then
			matches = matches and position.is_valid(value)
		elseif t == "Vector3" then
			matches = matches and typeof(value) == "Vector3"
		else
			error("Unhandled argument type "..t)
		end
	end
	return matches
end


local function construct_scheme_not_found_error(event, params)
	local types = {}
	local values = {}
	for i, val in params :: {[number]: any} do
		types[i] = typeof(val)
		values[i] = tostring(val)
	end
	local messages = {}
	table.insert(messages, `No matching scheme found for event {event.Name}`)
	table.insert(messages, "Types: "..table.concat(types, ", "))
	table.insert(messages, "Values: "..table.concat(values, ", "))
	table.insert(messages, "Available schemes:")

	for cb, scheme in schemas[event] do
		local msg = `Function {debug.info(cb, "n")} defined at line {debug.info(cb, "l")}: {table.concat(scheme, ", ")}`
		table.insert(messages, msg)
	end
	
	return table.concat(messages, "\n")
end


local function on_event(event, ...)
	local callback = nil
	for cb, scheme in schemas[event] do
		if scheme_matches(scheme, ...) then
			if callback == nil then
				callback = cb
			else
				error("Ambiguous choice in scheme "..table.concat(scheme, ", "))
			end
		end
	end
	
	if callback == nil then
		error(construct_scheme_not_found_error(event, {...}))
	else
		callback(...)
	end
end


function replication.bind_event(event, callback, ...)
	if schemas[event] == nil then
		schemas[event] = {}
		if runService:IsServer() then
			event.OnServerEvent:Connect(function(...)
				on_event(event, ...)
			end)
		else
			event.OnClientEvent:Connect(function(...)
				on_event(event, ...)
			end)
		end
	end
	schemas[event][callback] = {...}
end


return true