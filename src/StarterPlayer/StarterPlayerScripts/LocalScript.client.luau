--!strict
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local plot = require(common.Plot)
local cursor = require(contracts.Cursor)
local actionManager = require(contracts.ActionManager)
local gamestate = require(common.GameState)
local actor = require(common.Actor.Actor)
local replication = require(common.Replication)
local dragModes = require(common.DragModes)
local Asset = require(common.Asset.Asset)

local bootloaded_total = 0
local bootloaded_success = 0
local function bootload_folder(folder: Folder)
	for _, module in folder:GetChildren() do
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
	bootload_folder(replicatedStorage.CommonImplementations)
	bootload_folder(replicatedStorage.CommonImplementations.Actor)
	bootload_folder(replicatedStorage.CommonImplementations.Asset)
	bootload_folder(replicatedStorage.CommonImplementations.Data)
	bootload_folder(replicatedStorage.Client.Implementations)
	bootload_folder(replicatedStorage.Client.Implementations.Actor)
	bootload_folder(replicatedStorage.Client.Implementations.Asset)
	bootload_folder(replicatedStorage.Client.Implementations.Cursor)
	bootload_folder(replicatedStorage.Client.Implementations.UI)
	bootload_folder(replicatedStorage.Common)
	print(`Succesfully loaded {bootloaded_success}/{bootloaded_total} modules`)

	Asset.set_append_from_folder(Asset.assets, replicatedStorage.Assets.Models)
	Asset.set_append_from_folder(Asset.animations, replicatedStorage.Assets.Animations)
	Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images))
	Asset.set_append(Asset.translations, require(replicatedStorage.Assets.Translations))
	Asset.set_append(Asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))

	gamestate.set_ready()
end
bootload()


actionManager.bind("action", Enum.UserInputType.MouseButton1)
actionManager.bind("rotate", Enum.KeyCode.R)

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
	plot.build(p)
end
replicatedStorage.Remotes.PlotReplicateEvent.OnClientEvent:Connect(on_plot_load)
replicatedStorage.Remotes.PlotReplicateEvent:FireServer()


local function on_plot_build(pos, layerName, assetName)
	local p = plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end

	local gridlayer = plot.gridlayer_get(p, layerName, pos.pos.Y)
	if gridlayer == nil then
		return
	end

	plot.gridlayer_set_asset(gridlayer, pos, assetName)
	plot.update_push(pos)
	plot.build(p)
end


local function on_plot_build_drag(from, pos, layerName, assetName, dragmode)
	local p = plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end

	local gridlayer = plot.gridlayer_get(p, layerName, pos.pos.Y)
	if gridlayer == nil then
		return
	end

	for _, pos2 in dragModes.get_positions(layerName, from, pos, dragmode) do
		plot.gridlayer_set_asset(gridlayer, pos2, assetName)
		plot.update_push(pos2)
	end
	plot.build(p)
end


replication.bind_event(
	replicatedStorage.Remotes.PlotBuildEvent,
	on_plot_build,
	"position",
	"string",
	"string"
)
replication.bind_event(
	replicatedStorage.Remotes.PlotBuildEvent,
	on_plot_build_drag,
	"Vector3",
	"position",
	"string",
	"string",
	"string"
)


local function update(dt: number)
	cursor.update()
	actor.tick(dt)
end
runService.Heartbeat:Connect(update)