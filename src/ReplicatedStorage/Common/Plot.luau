--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local asset = require(common.Asset.Asset)

export type gridlayer = {
	type: layer_type,
	name: string,
	height: number,
	assets: {string},
	collision: {boolean},
	assets_built: {string},
	assets_models: {Model}
}

export type plot = {
	origin: CFrame,
	layers: {gridlayer},
	size: Vector2int16,
	owner: Player?,
	dirty: boolean,
	folder: Folder,
	updates: {position.position},
	layers_computed: {gridlayer}
}

export type layer_type = "center" | "edge"
export type layer = {
	get_index: (plot: plot, x: number, z: number, rotation: number) -> number,
	get_position: (plot: plot, idx: number) -> position.position,
	build: (plot: plot, gridlayer: gridlayer, destination: Instance) -> (),
	build_cell: (p: plot, gridlayer: gridlayer, pos: position.position, destination: Instance) -> (),
	resize: (src: {string}, from: Vector2int16, to: Vector2int16) -> {string}
}


return {
	layers = {}
} :: {
	allPlots: {[Folder]: plot},
	build: (plot: plot) -> (),
	build_asset: (pos: position.position, name: string, asset: string) -> boolean,
	get_asset: (pos: position.position, layer: string) -> string,
	
	get_by_owner: (owner: Player) -> {plot},
	get_by_folder: (folder: Folder?) -> plot?,
	create_from_folder: (folder: Folder) -> plot,
	is_valid_folder: (folder: Instance) -> (boolean, string),
	
	claim: (plot: plot, player: Player) -> boolean,
	unclaim: (plot: plot, player: Player) -> boolean,
	
	gridlayer_attach: (plot: plot, type: layer_type, name: string, height: number) -> (),
	gridlayer_get: (plot: plot, name: string, height: number) -> gridlayer?,
	gridlayer_get_computed: (plot: plot, name: string, height: number) -> gridlayer?,
	gridlayer_get_asset: (layer: gridlayer, pos: position.position) -> string,
	gridlayer_set_asset: (layer: gridlayer, pos: position.position, asset: string) -> boolean,
	gridlayer_get_collision: (layer: gridlayer, pos: position.position) -> boolean,
	gridlayer_set_collision: (layer: gridlayer, pos: position.position, filled: boolean) -> (),
	
	collisionmesh_collides: (pos: position.position, mesh: asset.collisionmesh) -> boolean,
	collisionmesh_place: (pos: position.position, mesh:asset.collisionmesh) -> (),
	collisionmesh_remove: (pos: position.position, mesh:asset.collisionmesh) -> (),
	
	pathfind_update_map: (p: plot) -> (),
	pathfind_to: (from: position.position, to: position.position) -> {position.position},
	
	replicate: (plot: plot) -> (),
	update_push: (pos: position.position) -> (),
	update_execute_all: (plot: plot) -> (),

	layers: {
		[string]: layer
	},
	
	save: (plot: plot) -> (),
	load: (plot: plot, player: Player) -> (),
	
	asset_seek: (plot: plot, layerName: string, assetName: string) -> {position.position}
}