--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local contracts = script.Contracts
local common = replicatedStorage.Common
local plot = require(common.Plot)
local position = require(common.Data.Position)
local replication = require(common.Replication)
local asset = require(common.Asset.Asset)
local actor = require(common.Actor.Actor)
local customer = require(common.Actor.Customer)
local dragModes = require(common.DragModes)
local data = require(contracts.Data)
local tycoon = require(common.Game.Tycoon)


local bootload = require(script.Bootloader)


local function update(dt: number)
	actor.tick(dt)
	customer.tick(dt)
end

replicatedStorage.Remotes.StatEvent.OnServerEvent:Connect(function(player: Player)
	local sessionData = data.load_data(player)
	replicatedStorage.Remotes.StatEvent:FireClient(player, "currency", sessionData.currency)
end)


local function player_join(player: Player)
	local sessionData = data.load_data(player)
	if runService:IsStudio() then
		sessionData.currency = 1000000
	end
	
	local p1 = plot.create_from_folder(workspace.Grid1)
	plot.gridlayer_attach(p1, "center", "floor", 0)
	plot.gridlayer_attach(p1, "edge", "wall_inner", 0)
	plot.gridlayer_attach(p1, "edge", "wall_outer", 0)
	plot.gridlayer_attach(p1, "center", "ceiling", 0)
	plot.gridlayer_attach(p1, "edge", "asset", 0)
	plot.gridlayer_attach(p1, "edge", "light", 0)
	plot.gridlayer_attach(p1, "center", "floor", 1)
	plot.gridlayer_attach(p1, "edge", "wall_inner", 1)
	plot.gridlayer_attach(p1, "edge", "wall_outer", 1)
	plot.gridlayer_attach(p1, "center", "ceiling", 1)
	plot.gridlayer_attach(p1, "edge", "asset", 1)
	plot.gridlayer_attach(p1, "edge", "light", 1)
	plot.gridlayer_attach(p1, "center", "floor", 2)
	plot.gridlayer_attach(p1, "edge", "wall_inner", 2)
	plot.gridlayer_attach(p1, "edge", "wall_outer", 2)
	plot.gridlayer_attach(p1, "center", "ceiling", 2)
	plot.gridlayer_attach(p1, "edge", "asset", 2)
	plot.gridlayer_attach(p1, "edge", "light", 2)

	plot.claim(p1, player)
	plot.replicate(p1)
	
	customer.spawn({
		pos = Vector3.new(0, 0, 0),
		rot = 0,
		plot = p1.folder
	}, "Npc")
end


local function player_leave(player: Player)
	for _, p in plot.get_by_owner(player) do
		plot.save(p)
	end
end


local function main()
	bootload()
	replication.bind_event(
		replicatedStorage.Remotes.PlotBuildEvent,
		tycoon.build,
		"Player",
		"Vector3",
		"position",
		"string",
		"string"
	)
	replication.bind_event(
		replicatedStorage.Remotes.PlotDeleteEvent,
		tycoon.delete,
		"Player",
		"Vector3", -- From
		"position", -- To
		"string", -- Layer,
		"string" -- dragMode
	)
end


runService.Heartbeat:Connect(update)
main()


players.PlayerRemoving:Connect(player_leave)
players.PlayerAdded:Connect(player_join)
for _, player in players:GetPlayers() do
	player_join(player)
end

print("Finished")