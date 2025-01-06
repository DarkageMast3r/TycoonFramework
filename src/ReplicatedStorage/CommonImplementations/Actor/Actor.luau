--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local actor = require(common.Actor.Actor)
local asset = require(common.Asset.Asset)
local animation = require(common.Asset.Animation)
local plot = require(common.Plot)

actor.allActors = {}
local actors_by_plot: {
	[Folder]: {actor.actor}
} = {}

function actor.spawn(pos, meshName, idHint)
	local a = actor.create(pos, meshName, idHint)
	table.insert(actor.allActors, a)
	local plot = pos.plot
	if plot ~= nil then
		if actors_by_plot[plot] == nil then
			actors_by_plot[plot] = {}
		end
		table.insert(actors_by_plot[plot], a)
	end
	
	if runService:IsServer() then
		actor.replicate(a)
	end
	
	return a
end


function actor.despawn(a)
	local mesh = a.mesh
	if mesh ~= nil then
		mesh:Destroy()
	end
	a.waypoint_reached:Destroy()
	a.target_reached:Destroy()
	local idx = table.find(actor.allActors, a)
	if idx ~= nil then
		table.remove(actor.allActors, idx)
	end
	if runService:IsServer() then
		replicatedStorage.Remotes.ActorDespawnEvent:FireAllClients(a.id)
	end
end
if runService:IsClient() then
	replicatedStorage.Remotes.ActorDespawnEvent.OnClientEvent:Connect(function(id)
		local a = actor.get_by_id(id)
		if a == nil then
			return
		end
		actor.despawn(a)
	end)
end


function actor.animation_load(a, type, name)
	if a.mesh == nil then
		return
	end
	
	local anim = animation.create_by_name(a.mesh, name)
	if anim ~= nil then
		a.animations[type] = anim
	end
end


function actor.animation_play(a, type, fadeTime)
	for t, anim in a.animations do
		anim:Stop(fadeTime)
	end
	
	local track = a.animations[type]
	if track == nil then
		return
	end
	
	track:Play(fadeTime)
end


function actor.get_in_plot(pos)
	local plot = pos.plot
	if plot == nil or actors_by_plot[plot] == nil then
		return {}
	end
	return actors_by_plot[plot]
end


function actor.get_in_box(pos, size)
	size -= Vector3.one

	local found = {}
	for _, a in actor.get_in_plot(pos) do
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


function actor.get_in_radius(pos, radius)
	local found = {}
	for _, a in actor.get_in_plot(pos) do
		local rel = a.position.pos - pos.pos
		if rel.Magnitude <= radius then
			table.insert(found, a)
		end
	end
	return found
end


function actor.get_by_id(id)
	for _, a in actor.allActors do
		if a.id == id then
			return a
		end
	end
	return nil
end


function actor.switch_to_state(a: actor.actor, state: string)
	a.state = state
	actor.states[state].init(a)
end


function actor.tick(dt: number)
	for _, a in actor.allActors do
		actor.states[a.state].update(a, dt)
	end
end


return true