--!strict
local serverScriptService = game:GetService("ServerScriptService")
local pathfindingService = game:GetService("PathfindingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local contracts = serverScriptService.Script.Contracts
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local data = require(contracts.Data)
local profileStore = require(contracts.ProfileStore)
local asset = require(common.Asset.Asset)

local datastores = {}
local function datastore_create(name: string, stub: {[any]: any})
	datastores[name] = {
		stub = stub,
		profiles = {},
		profiles_loading = {},
		datastore = profileStore.New(name, stub)
	}
end


local function datastore_get(name: string, player: Player, key: string): any
	local datastore = datastores[name]
	if datastore == nil then
		error(`No datastore found by name {name}!`)
	end
	if datastore.profiles[key] == nil then
		if datastore.profiles_loading[key] and not datastore.profiles[key] then
			repeat task.wait()
			until datastore.profiles[key]
			return datastore.profiles[key].Data
		end
		
		datastore.profiles_loading[key] = true
		local profile = datastore.datastore:StartSessionAsync(key, {
			Cancel = function()
				return player.Parent ~= players
			end
		})
		if profile == nil then
			player:Kick("Could not load data, please rejoin.")
			return {layers={}}
		end
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			datastore.profiles[key] = nil
			player:Kick(`Profile session end, please rejoin.`)
		end)

		if player.Parent ~= players then
			profile:EndSession()
			return {layers={}}
		end

		datastore.profiles[key] = profile
	end

	return datastore.profiles[key].Data
end

local datastore_plot = profileStore.New("Plots", {
	layers = {}
} :: data.plot_serialized)
local profiles = {}

datastore_create("Plots", {
	layers = {}
})
datastore_create("Data", {
	currency = 0
})

function data.load_plot(player)
	return datastore_get("Plots", player, `plot_{player.UserId}`)
end


function data.load_data(player)
	return datastore_get("Data", player, `data_{player.UserId}`)
end


return true