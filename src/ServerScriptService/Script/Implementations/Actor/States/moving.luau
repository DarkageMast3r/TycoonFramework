local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)

local State = {}


function State.init(actor)
	Actor.animation_play(actor, "walk", 0.2)
end


local function advance_waypoint(actor: Actor.actor)
	actor.waypoint_reached:Fire(actor, actor.path[1].pos)
	table.remove(actor.path, 1)
end


function State.update(actor, dt)
	--[[
		When calculating a new path, the actor should be set to state = moving,
		but the path calculation doesn't finish immediately. 
		The path waypoints get supplied some time later, so a.target = nil while these get calculated.
	]]
	if actor.target == nil then
		return
	end
	
	local distance_to_travel = dt * actor.speed
	repeat
		local cur = actor.position.pos
		local target = actor.path[1].pos
		local dis = (target - cur).Magnitude
		local stride = math.min(distance_to_travel, dis)
		if stride == 0 then
			advance_waypoint(actor)
			break
		end
		distance_to_travel -= stride
		actor.position.pos = cur:Lerp(target, math.clamp(stride/dis, 0, 1))
		if distance_to_travel > 0.0001 then
			advance_waypoint(actor)
		end
	until distance_to_travel < 0.0001 or actor.path[1] == nil
	
	if actor.path[1] == nil then
		local target = actor.target
		actor.target = nil
		actor.target_reached:Fire(actor, target)
		Actor.switch_to_state(actor, "idle")
	end
end


return State