--!strict
local serverScriptService = game:GetService("ServerScriptService")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")

local contracts = script.Parent.OTF.Contracts
local common = replicatedStorage.OTF.Common
local custom = script.Parent.Custom.Contracts
local Plot = require(common.Plot)
local Replication = require(common.Replication)
local Actor = require(common.Actor.Actor)
local Customer = require(custom.Customer)
local Data = require(contracts.Data)
local Tycoon = require(common.Game.Tycoon)
local OTF = require(serverScriptService.OTF)


local function update(dt: number)
	Actor.tick(dt)
	Customer.tick(dt)

	for _, player in players:GetPlayers() do
		Data.replicate_data(player)
	end
end

replicatedStorage.Remotes.StatEvent.OnServerEvent:Connect(function(player: Player)
	local sessionData = Data.load_data(player)
	replicatedStorage.Remotes.StatEvent:FireClient(player, "currency", sessionData.currency)
end)


local function player_join(player: Player)
	local sessionData = Data.load_data(player)
	if runService:IsStudio() then
		sessionData.currency = 1000000
	end

	for _, plot in Plot.allPlots do
		Plot.replicate_to(plot, player)
	end
end


local function try_claim(player: Player, plot_folder: Folder)
	local plot = Plot.get_by_folder(plot_folder)
	if plot == nil then
		return
	end
	Plot.claim(plot, player)
end


local function player_leave(player: Player)
	for _, plot in Plot.get_by_owner(player) do
		Plot.save(plot)
		Plot.unclaim(plot, player)
	end
end


local function main()
	OTF.bootload_folder(serverScriptService.Custom.Implementations)
	OTF.load()

	collectionService:GetInstanceAddedSignal("Grid", Plot.create_from_folder)
	for _, grid in collectionService:GetTagged("Grid") do
		Plot.create_from_folder(grid)
	end

	Replication.bind_event(
		replicatedStorage.Remotes.PlotBuildEvent,
		Tycoon.build,
		"Player",
		"Vector3",
		"position",
		"string",
		"string"
	)
	Replication.bind_event(
		replicatedStorage.Remotes.PlotDeleteEvent,
		Tycoon.delete,
		"Player",
		"Vector3", -- From
		"position", -- To
		"string", -- Layer,
		"string" -- dragMode
	)
	Replication.bind_event(
		replicatedStorage.Remotes.PlotClaimEvent,
		try_claim,
		"Player",
		"Folder"
	)

	Tycoon.on_build("Drawer", "asset", function(plot, position, asset, layer)
		local gridlayer = Plot.gridlayer_get(plot, layer, position.pos.Y)
		if gridlayer == nil then
			return
		end
		Plot.gridlayer_set_metadata(gridlayer, position, {
			apples = math.random(1, 10),
			bananas = math.random(1, 10)
		})
		local metadata = Plot.gridlayer_get_metadata(gridlayer, position)
		print(metadata)
	end)
	Tycoon.on_delete("Drawer", "asset", function(plot, position, asset, layer)
		local gridlayer = Plot.gridlayer_get(plot, layer, position.pos.Y)
		if gridlayer == nil then
			return
		end
		local metadata = Plot.gridlayer_get_metadata(gridlayer, position)
		print(metadata)
	end)
end


runService.Heartbeat:Connect(update)
main()


players.PlayerRemoving:Connect(player_leave)
players.PlayerAdded:Connect(player_join)
for _, player in players:GetPlayers() do
	player_join(player)
end