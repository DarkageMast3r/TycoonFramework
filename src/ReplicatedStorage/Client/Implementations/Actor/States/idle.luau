local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)

local state = {}

function state.init(actor)
	Actor.animation_play(actor, "idle", 0.2)
end

function state.update(a, dt)
	
end

return state