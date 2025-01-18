--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local contracts = serverScriptService.Script.Contracts
local common = replicatedStorage.Common
local Position = require(common.Data.Position)
local Tycoon = require(common.Game.Tycoon)
local Plot = require(common.Plot)
local Asset = require(common.Asset.Asset)
local DragModes = require(common.DragModes)
local Data = require(contracts.Data)

type plot_callback<t> = {[string]: {[string]: {t}}}
local callbacks_build: plot_callback<Tycoon.asset_build_callback> = {}
local callbacks_delete: plot_callback<Tycoon.asset_delete_callback> = {}


local plot_callback_memo = {}
local function plot_callback_query<t>(collection: plot_callback<t>, asset: string, layer: string): {t}
	plot_callback_memo[collection] = plot_callback_memo[collection] or {}
	if plot_callback_memo[collection][asset] then
		return plot_callback_memo[collection][asset]
	end

	local result = {}
	plot_callback_memo[collection][asset] = result
	if collection[layer] == nil then
		return result
	end
	for asset_query, callbacks in collection[layer] do
		if asset:find(asset_query) then
			for _, callback in callbacks do
				table.insert(result, callback)
			end
		end
	end
	return result
end


function Tycoon.build(
	player: Player,
	from: Vector3,
	to: Position.position,
	assetName: string,
	dragmode: string
)
	local plot = Plot.get_by_folder(to.plot)
	if plot == nil then
		return
	end
	if plot.owner ~= player then
		return
	end

	local assetInfo = Asset.set_fetch(Asset.assetInfo, assetName)
	if assetInfo.price == math.huge then
		return
	end
	
	local playerData = Data.load_data(player)
	local layer = Asset.resolve_type(assetName)

	local callbacks = plot_callback_query(callbacks_build, assetName, layer)
	for _, position in DragModes.get_positions(layer, from, to, dragmode) do
		if Plot.get_asset(position, layer) ~= "" then
			continue
		end
		if assetInfo.price > playerData.currency then
			break
		end
		playerData.currency -= assetInfo.price
		Plot.build_asset(position, layer, assetName)
		for _, callback in callbacks do
			callback(plot, position, assetName, layer)
		end
	end

	replicatedStorage.Remotes.PlotBuildEvent:FireClient(player, from, to, layer, assetName, dragmode)
end


function Tycoon.delete(
	player: Player,
	from: Vector3,
	to: Position.position,
	layer: string,
	dragmode: string
)
	local plot = Plot.get_by_folder(to.plot)
	if plot == nil then
		return
	end
	if plot.owner ~= player then
		return
	end

	local playerData = Data.load_data(player)

	for _, position in DragModes.get_positions(layer, from, to, dragmode) do
		local currentAsset = Plot.get_asset(position, layer)
		local assetInfo = Asset.set_fetch(Asset.assetInfo, currentAsset)
		if assetInfo.price ~= math.huge then
			playerData.currency += assetInfo.price
		end
		Plot.build_asset(position, layer, "")
		for _, callback in plot_callback_query(callbacks_delete, currentAsset, layer) do
			callback(plot, position, currentAsset, layer)
		end
	end

	replicatedStorage.Remotes.PlotBuildEvent:FireClient(player, from, to, layer, "", dragmode)
end


function Tycoon.on_build(asset, layer, callback)
	callbacks_build[layer] = callbacks_build[layer] or {}
	callbacks_build[layer][asset] = callbacks_build[layer][asset] or {}
	table.insert(callbacks_build[layer][asset], callback)
end


function Tycoon.on_delete(asset, layer, callback)
	callbacks_delete[layer] = callbacks_delete[layer] or {}
	callbacks_delete[layer][asset] = callbacks_delete[layer][asset] or {}
	table.insert(callbacks_delete[layer][asset], callback)
end


function Tycoon.on_build_fire(plot, position, asset, layer)
	for _, callback in plot_callback_query(callbacks_build, asset, layer) do
		callback(plot, position, asset, layer)
	end
end


function Tycoon.on_delete_fire(plot, position, asset, layer)
	for _, callback in plot_callback_query(callbacks_delete, asset, layer) do
		callback(plot, position, asset, layer)
	end
end


return true
