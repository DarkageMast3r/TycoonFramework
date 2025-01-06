--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common

local position = require(common.Data.Position)

return {} :: {
	get_positions: (mode: string, from: Vector3, to: position.position, dragmode: string) -> {position.position}
}