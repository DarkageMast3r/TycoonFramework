--!strict
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Plot = require(common.Plot)
local Cursor = require(contracts.Cursor)
local ActionManager = require(contracts.ActionManager)
local GameState = require(common.GameState)
local Actor = require(common.Actor.Actor)
local Replication = require(common.Replication)
local DragModes = require(common.DragModes)
local Asset = require(common.Asset.Asset)

local bootloaded_total = 0
local bootloaded_success = 0
local function bootload_folder(folder: Folder, recursive: boolean?)
	for _, module in folder:GetChildren() do
		if module:IsA("Folder") and recursive then
			bootload_folder(module, recursive)
		end
		if module:IsA("ModuleScript") then
			local success, message = pcall(require, module)
			bootloaded_total += 1
			if success then
				bootloaded_success += 1
			else
				warn(message)
			end
		end
	end
end


local function bootload()
	require(contracts.Parent.Implementations.ActionManager)
	bootload_folder(replicatedStorage.OTF.CommonImplementations, true)
	bootload_folder(replicatedStorage.OTF.Client.Implementations.Asset, true)
	bootload_folder(replicatedStorage.OTF.Client, true)
	print(`Succesfully loaded {bootloaded_success}/{bootloaded_total} modules`)

	Asset.set_append_from_folder(Asset.assets, replicatedStorage.Assets.Models)
	Asset.set_append_from_folder(Asset.animations, replicatedStorage.Assets.Animations)
	Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images))
	Asset.set_append(Asset.translations, require(replicatedStorage.Assets.Translations))
	Asset.set_append(Asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))

	GameState.set_ready()
end
bootload()


ActionManager.bind("action", Enum.UserInputType.MouseButton1)
ActionManager.bind("rotate", Enum.KeyCode.R)

local itemlist = {
	"Floor.Wood",
	"Floor.Marble",
	"Floor.Carpet",
	"Floor.Carpet.Red",
	"Floor.Carpet.Green",
	"Floor.Squirgle",
	"Wall_Outer.Brick",
	"Wall_Outer.Wood",
	"Wall_Outer.Squirgle",
	"Ceiling.Office"
}

local function on_plot_load(p)
	Plot.build(p)
end
replicatedStorage.Remotes.PlotReplicateEvent.OnClientEvent:Connect(on_plot_load)
replicatedStorage.Remotes.PlotReplicateEvent:FireServer()


local function on_plot_build(pos, layerName, assetName)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end

	local gridlayer = Plot.gridlayer_get(p, layerName, pos.pos.Y)
	if gridlayer == nil then
		return
	end

	Plot.gridlayer_set_asset(gridlayer, pos, assetName)
	Plot.update_push(pos)
	Plot.build(p)
end


local function on_plot_build_drag(from, pos, layerName, assetName, dragmode)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end

	local gridlayer = Plot.gridlayer_get(p, layerName, pos.pos.Y)
	if gridlayer == nil then
		return
	end

	for _, pos2 in DragModes.get_positions(layerName, from, pos, dragmode) do
		Plot.gridlayer_set_asset(gridlayer, pos2, assetName)
		Plot.update_push(pos2)
	end
	Plot.build(p)
end


Replication.bind_event(
	replicatedStorage.Remotes.PlotBuildEvent,
	on_plot_build,
	"position",
	"string",
	"string"
)
Replication.bind_event(
	replicatedStorage.Remotes.PlotBuildEvent,
	on_plot_build_drag,
	"Vector3",
	"position",
	"string",
	"string",
	"string"
)


local function update(dt: number)
	Cursor.update()
	Actor.tick(dt)
end
runService.Heartbeat:Connect(update)