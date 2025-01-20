--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local Position = require(common.Data.Position)
local AssetInfo = require(replicatedStorage.Assets.AssetInfo)

export type collisionmesh_layer = {
	{pos: Position.position, mode: number}
}
export type collisionmesh = {
	[string]: collisionmesh_layer
}
type asset_collection<t> = {
	[string]: t
}

return {
	assets = {},
	animations = {},
	images = {},
	translations = {},
	assetInfo = {}
} :: {
	assets: asset_collection<Model>,
	animations: asset_collection<Animation>,
	images: asset_collection<number>,
	translations: asset_collection<string>,
	assetInfo: asset_collection<AssetInfo.assetInfo>,

	set_append: <t>(asset_collection<t>, {[string]: t}) -> (),
	set_append_from_folder: <t>(asset_collection<t>, Folder) -> (),
	set_fetch: <t>(asset_collection<t>, string) -> t,
	set_key_resolve: <t>(asset_collection<t>, string) -> string,
	
	set_uninteractable: (model: Model) -> (),
	create_by_name: (name: string) -> Model,
	resolve_type: (name: string) -> string,
	modifier_add: (name: string, modifier: string) -> string,
	modifier_remove: (name: string, modifier: string) -> string,
	modifier_get: (name: string) -> {[string]: boolean},
	without_modifiers: (name: string) -> string,
	move_to: (asset: Model, pos: Position.position) -> (),
	collisionmesh_get: (name: string) -> collisionmesh
}