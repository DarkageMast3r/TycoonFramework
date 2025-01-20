--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common

local Position = require(common.Data.Position)
local Plot = require(common.Plot)

export type asset_build_callback = (Plot.plot, Position.position, asset: string, layer: string) -> ()
export type asset_delete_callback = (Plot.plot, Position.position, asset: string, layer: string) -> ()

return {} :: {
	build: (player: Player, from: Vector3, to: Position.position, asset: string, dragmode: string) -> (),
	delete: (player: Player, from: Vector3, to: Position.position, layer: string, dragmode: string) -> (),

	on_build: (asset: string, layer: string, callback: asset_build_callback) -> (),
	on_delete: (asset: string, layer: string, callback: asset_delete_callback) -> (),

	on_build_fire: (Plot.plot, Position.position, asset: string, layer: string) -> (),
	on_delete_fire: (Plot.plot, Position.position, asset: string, layer: string) -> ()
}