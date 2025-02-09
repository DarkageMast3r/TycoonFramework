--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common
local Position = require(common.Data.Position)
local Asset = require(common.Asset.Asset)

export type gridlayer = {
	type: layer_type,
	name: string,
	height: number,
	assets: {string},
	collision: {boolean},
	assets_built: {string},
	assets_models: {Model},
	metadata: {any}
}

export type plot = {
	origin: CFrame,
	layers: {gridlayer},
	size: Vector2int16,
	owner: Player?,
	dirty: boolean,
	folder: Folder,
	updates: {Position.position},
	layers_computed: {gridlayer}
}

export type layer_type = "center" | "edge"
export type layer = {
	get_index: (plot: plot, x: number, z: number, rotation: number) -> number,
	get_position: (plot: plot, idx: number) -> Position.position,
	build: (plot: plot, gridlayer: gridlayer, destination: Instance) -> (),
	build_cell: (p: plot, gridlayer: gridlayer, pos: Position.position, destination: Instance) -> (),
	resize: (src: {string}, from: Vector2int16, to: Vector2int16) -> {string}
}


return {
	layers = {}
} :: {
	allPlots: {[Folder]: plot},
	build: (plot: plot, rebuild: boolean?) -> (),
	build_asset: (pos: Position.position, name: string, asset: string) -> boolean,
	get_asset: (pos: Position.position, layer: string) -> string,
	
	get_by_owner: (owner: Player) -> {plot},
	get_by_folder: (folder: Folder?) -> plot?,
	get_unclaimed: (folder: Folder?) -> {plot},
	create_from_folder: (folder: Folder) -> plot,
	is_valid_folder: (folder: Instance) -> (boolean, string),
	
	claim: (plot: plot, player: Player) -> boolean,
	unclaim: (plot: plot, player: Player) -> boolean,
	
	gridlayer_attach: (plot: plot, type: layer_type, name: string, height: number) -> (),
	gridlayer_get: (plot: plot, name: string, height: number) -> gridlayer?,
	gridlayer_get_computed: (plot: plot, name: string, height: number) -> gridlayer?,
	gridlayer_get_asset: (layer: gridlayer, pos: Position.position) -> string,
	gridlayer_set_asset: (layer: gridlayer, pos: Position.position, asset: string) -> boolean,
	gridlayer_get_metadata: (layer: gridlayer, pos: Position.position) -> any,
	gridlayer_set_metadata: (layer: gridlayer, pos: Position.position, metadata: any) -> (),
	gridlayer_get_collision: (layer: gridlayer, pos: Position.position) -> boolean,
	gridlayer_set_collision: (layer: gridlayer, pos: Position.position, filled: boolean) -> (),
	
	collisionmesh_collides: (pos: Position.position, mesh: Asset.collisionmesh) -> boolean,
	collisionmesh_place: (pos: Position.position, mesh: Asset.collisionmesh) -> (),
	collisionmesh_remove: (pos: Position.position, mesh: Asset.collisionmesh) -> (),
	
	pathfind_update_map: (p: plot) -> (),
	pathfind_to: (from: Position.position, to: Position.position) -> {Position.position},
	
	replicate: (plot: plot) -> (),
	replicate_to: (plot: plot, player: Player) -> (),
	update_push: (pos: Position.position) -> (),
	update_execute_all: (plot: plot) -> (),

	layers: {
		[string]: layer
	},
	
	save: (plot: plot) -> (),
	load: (plot: plot, player: Player) -> (),
	
	asset_seek: (plot: plot, layerName: string, assetName: string) -> {Position.position}
}