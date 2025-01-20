local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)

local State = {}

function State.init(actor)
	Actor.animation_play(actor, "idle", 0.2)
end

function State.update(actor, dt)
end

return State