--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common

local position = require(common.Data.Position)


return {} :: {
	build: (player: Player, from: Vector3, to: position.position, asset: string, dragmode: string) -> (),
	delete: (player: Player, from: Vector3, to: position.position, layer: string, dragmode: string) -> ()
}