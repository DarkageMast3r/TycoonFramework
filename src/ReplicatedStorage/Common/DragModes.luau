--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common

local Position = require(common.Data.Position)

return {} :: {
	get_positions: (mode: string, from: Vector3, to: Position.position, dragmode: string) -> {Position.position}
}