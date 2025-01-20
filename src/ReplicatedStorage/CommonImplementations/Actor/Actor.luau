--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)
local Animation = require(common.Asset.Animation)

Actor.allActors = {}
local actors_by_plot: {
	[Folder]: {Actor.actor}
} = {}

function Actor.spawn(pos, meshName, idHint)
	local a = Actor.create(pos, meshName, idHint)
	table.insert(Actor.allActors, a)
	local plot = pos.plot
	if plot ~= nil then
		if actors_by_plot[plot] == nil then
			actors_by_plot[plot] = {}
		end
		table.insert(actors_by_plot[plot], a)
	end
	
	if runService:IsServer() then
		Actor.replicate(a)
	end
	
	return a
end


function Actor.despawn(a)
	local mesh = a.mesh
	if mesh ~= nil then
		mesh:Destroy()
	end
	a.waypoint_reached:Destroy()
	a.target_reached:Destroy()
	local idx = table.find(Actor.allActors, a)
	if idx ~= nil then
		table.remove(Actor.allActors, idx)
	end
	if runService:IsServer() then
		replicatedStorage.Remotes.ActorDespawnEvent:FireAllClients(a.id)
	end
end
if runService:IsClient() then
	replicatedStorage.Remotes.ActorDespawnEvent.OnClientEvent:Connect(function(id)
		local a = Actor.get_by_id(id)
		if a == nil then
			return
		end
		Actor.despawn(a)
	end)
end


function Actor.animation_load(a, type, name)
	if a.mesh == nil then
		return
	end
	
	local anim = Animation.create_by_name(a.mesh, name)
	if anim ~= nil then
		a.animations[type] = anim
	end
end


function Actor.animation_play(a, type, fadeTime)
	for t, anim in a.animations do
		anim:Stop(fadeTime)
	end
	
	local track = a.animations[type]
	if track == nil then
		return
	end
	
	track:Play(fadeTime)
end


function Actor.get_in_plot(pos)
	local plot = pos.plot
	if plot == nil or actors_by_plot[plot] == nil then
		return {}
	end
	return actors_by_plot[plot]
end


function Actor.get_in_box(pos, size)
	size -= Vector3.one

	local found = {}
	for _, a in Actor.get_in_plot(pos) do
		local rel = a.position.pos - pos.pos
		if math.abs(rel.X) <= size.X / 2
			and math.abs(rel.Y) <= size.Y / 2
			and math.abs(rel.Z) <= size.Z / 2
		then
			table.insert(found, a)
		end
	end
	return found
end


function Actor.get_in_radius(pos, radius)
	local found = {}
	for _, a in Actor.get_in_plot(pos) do
		local rel = a.position.pos - pos.pos
		if rel.Magnitude <= radius then
			table.insert(found, a)
		end
	end
	return found
end


function Actor.get_by_id(id)
	for _, a in Actor.allActors do
		if a.id == id then
			return a
		end
	end
	return nil
end


function Actor.switch_to_state(a: Actor.actor, state: string)
	a.state = state
	Actor.states[state].init(a)
end


function Actor.tick(dt: number)
	for _, a in Actor.allActors do
		Actor.states[a.state].update(a, dt)
	end
end


return true