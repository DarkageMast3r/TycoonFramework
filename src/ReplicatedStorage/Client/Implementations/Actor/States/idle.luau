local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local actor = require(common.Actor.Actor)
local plot = require(common.Plot)

local state = {}

function state.init(a)
	actor.animation_play(a, "idle", 0.2)
end

function state.update(a, dt)
	
end

return state