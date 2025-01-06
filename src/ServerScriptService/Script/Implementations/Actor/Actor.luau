--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local actor = require(common.Actor.Actor)
local position = require(common.Data.Position)
local plot = require(common.Plot)


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
	local a: actor.actor = {
		id = idHint or id_generate(),
		state = "idle",
		position = pos,
		target = nil,
		path = {},
		speed = 1,
		mesh = nil,
		meshName = meshName,
		animations = {},
		waypoint_reached = Instance.new("BindableEvent"),
		target_reached = Instance.new("BindableEvent")
	}
	return a
end


function actor.replicate(a)
	replicatedStorage.Remotes.ActorSpawnEvent:FireAllClients(a.position, a.meshName, a.id)
end


function actor.walk_to(a, pos)
	a.path = {}
	a.target = nil
	actor.switch_to_state(a, "moving")

	local from = {
		pos = a.position.pos:Floor(),
		rot = pos.rot,
		plot = pos.plot
	}
	local path = plot.pathfind_to(from, pos)
	a.target = pos
	a.path = path

	replicatedStorage.Remotes.ActorMoveEvent:FireAllClients(a.id, pos, path)
end


return true