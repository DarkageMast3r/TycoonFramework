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
	for _, position in DragModes.get_positions(layer, from, to, dragmode) do
		if Plot.get_asset(position, layer) ~= "" then
			continue
		end
		if assetInfo.price > playerData.currency then
			break
		end
		playerData.currency -= assetInfo.price
		Plot.build_asset(position, layer, assetName)
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
	local p = Plot.get_by_folder(to.plot)
	if p == nil then
		return
	end
	if p.owner ~= player then
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
	end

	replicatedStorage.Remotes.PlotBuildEvent:FireClient(player, from, to, layer, "", dragmode)
end


return true
