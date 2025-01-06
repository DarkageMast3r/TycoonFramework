--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local actor = require(common.Actor.Actor)
local asset = require(common.Asset.Asset)


for _, stateModule in script.Parent.States:GetChildren() do
	if not stateModule:IsA("ModuleScript") then
		continue
	end
	local stateData = require(stateModule)
	actor.states[stateModule.Name] = {
		init = stateData.init,
		update = stateData.update
	}
end


local id_cur = 0
local function id_generate()
	id_cur += 1
	return id_cur
end


function actor.create(pos, meshName, idHint)
	local mesh = asset.create_by_name(meshName)
	local a: actor.actor = {
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
	asset.move_to(mesh, a.position)
	mesh.Parent = workspace
	return a
end


function actor.walk_to(a, pos, path)
	a.target = pos
	a.path = path or {pos}
	actor.switch_to_state(a, "moving")
end


replicatedStorage.Remotes.ActorSpawnEvent.OnClientEvent:Connect(actor.spawn)
replicatedStorage.Remotes.ActorMoveEvent.OnClientEvent:Connect(function(id, pos, path)
	local a = actor.get_by_id(id)
	if a == nil then
		return
	end
	
	a.position = path[1]
	actor.walk_to(a, pos, path)
end)


return true