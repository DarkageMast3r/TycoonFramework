--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)
local Asset = require(common.Asset.Asset)


for _, stateModule in script.Parent.States:GetChildren() do
	if not stateModule:IsA("ModuleScript") then
		continue
	end
	local stateData = require(stateModule)
	Actor.states[stateModule.Name] = {
		init = stateData.init,
		update = stateData.update
	}
end


local id_cur = 0
local function id_generate()
	id_cur += 1
	return id_cur
end


function Actor.create(pos, meshName, idHint)
	local mesh = Asset.create_by_name(meshName)
	local a: Actor.actor = {
		id = idHint or id_generate(),
		state = "idle",
		position = pos,
		target = nil,
		path = {},
		speed = 1,
		mesh = mesh,
		meshName = meshName,
		animations = {},
		waypoint_reached = Instance.new("BindableEvent"),
		target_reached = Instance.new("BindableEvent")
	}
	Asset.move_to(mesh, a.position)
	mesh.Parent = workspace
	return a
end


function Actor.walk_to(actor, pos, path)
	actor.target = pos
	actor.path = path or {pos}
	Actor.switch_to_state(actor, "moving")
end


replicatedStorage.Remotes.ActorSpawnEvent.OnClientEvent:Connect(Actor.spawn)
replicatedStorage.Remotes.ActorMoveEvent.OnClientEvent:Connect(function(id, pos, path)
	local actor = Actor.get_by_id(id)
	if actor == nil then
		return
	end
	
	actor.position = path[1]
	Actor.walk_to(actor, pos, path)
end)


return true