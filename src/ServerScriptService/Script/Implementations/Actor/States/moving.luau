local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
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
	--[[
		When calculating a new path, the actor should be set to state = moving,
		but the path calculation doesn't finish immediately. 
		The path waypoints get supplied some time later, so a.target = nil while these get calculated.
	]]
	if a.target == nil then
		return
	end
	
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
	
	if a.path[1] == nil then
		local target = a.target
		a.target = nil
		a.target_reached:Fire(a, target)
		actor.switch_to_state(a, "idle")
	end
end


return state