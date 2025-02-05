--!strict
local serverScriptService = game:GetService("ServerScriptService")
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
	
	local p1 = Plot.create_from_folder(workspace.Grid1)
	Plot.gridlayer_attach(p1, "center", "floor", 0)
	Plot.gridlayer_attach(p1, "edge", "wall_inner", 0)
	Plot.gridlayer_attach(p1, "edge", "wall_outer", 0)
	Plot.gridlayer_attach(p1, "center", "ceiling", 0)
	Plot.gridlayer_attach(p1, "edge", "asset", 0)
	Plot.gridlayer_attach(p1, "edge", "light", 0)
	Plot.gridlayer_attach(p1, "center", "floor", 1)
	Plot.gridlayer_attach(p1, "edge", "wall_inner", 1)
	Plot.gridlayer_attach(p1, "edge", "wall_outer", 1)
	Plot.gridlayer_attach(p1, "center", "ceiling", 1)
	Plot.gridlayer_attach(p1, "edge", "asset", 1)
	Plot.gridlayer_attach(p1, "edge", "light", 1)
	Plot.gridlayer_attach(p1, "center", "floor", 2)
	Plot.gridlayer_attach(p1, "edge", "wall_inner", 2)
	Plot.gridlayer_attach(p1, "edge", "wall_outer", 2)
	Plot.gridlayer_attach(p1, "center", "ceiling", 2)
	Plot.gridlayer_attach(p1, "edge", "asset", 2)
	Plot.gridlayer_attach(p1, "edge", "light", 2)

	Plot.claim(p1, player)
	Plot.replicate(p1)
	
	Customer.spawn({
		pos = Vector3.new(0, 0, 0),
		rot = 0,
		plot = p1.folder
	}, "Npc")
end


local function player_leave(player: Player)
	for _, p in Plot.get_by_owner(player) do
		Plot.save(p)
	end
end


local function main()
	OTF.bootload_folder(serverScriptService.Custom.Implementations)
	OTF.load()
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