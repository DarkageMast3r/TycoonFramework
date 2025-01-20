local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common
local actor = require(common.Actor.Actor)
local asset = require(common.Asset.Asset)

local state = {}


function state.init(a)
	actor.animation_play(a, "walk", 0.2)
end


local function advance_waypoint(a: actor.actor)
	a.waypoint_reached:Fire(a, a.path[1].pos)
	table.remove(a.path, 1)
end


function state.update(a, dt)
	local distance_to_travel = dt * a.speed
	repeat
		local cur = a.position.pos
		local target = a.path[1].pos
		local dis = (target - cur).Magnitude
		local stride = math.min(distance_to_travel, dis)
		if stride == 0 then
			advance_waypoint(a)
			break
		end
		distance_to_travel -= stride
		a.position.pos = cur:Lerp(target, math.clamp(stride/dis, 0, 1))
		if distance_to_travel > 0.0001 then
			advance_waypoint(a)
		end
	until distance_to_travel < 0.0001 or a.path[1] == nil

	local mesh = a.mesh
	if mesh ~= nil then
		asset.move_to(mesh, a.position)
	end

	if a.path[1] == nil then
		local target = a.target
		a.target = nil
		a.target_reached:Fire(a, target)
		actor.switch_to_state(a, "idle")
	end
end

return state