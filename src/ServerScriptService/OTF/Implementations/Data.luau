--!strict
local serverScriptService = game:GetService("ServerScriptService")
local pathfindingService = game:GetService("PathfindingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local contracts = serverScriptService.OTF.Contracts
local common = replicatedStorage.OTF.Common
local Data = require(contracts.Data)
local ProfileStore = require(contracts.ProfileStore)


type diff_field<t> = {prev: t?, now: t?}
type diff = {
	[string]: diff_field<any>
}

local datastores = {}
local function datastore_create(name: string, stub: {[any]: any})
	datastores[name] = {
		stub = stub,
		profiles = {},
		profiles_loading = {},
		datastore = ProfileStore.New(name, stub),
		last_replicated = table.clone(stub)
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


-- TODO: Generate nested diff
local function diff_generate(prev: {[string]: any}, now: {[string]: any}): diff
	local diff = {}
	for i, v in now do
		if prev[i] == v then
			continue
		end
		if diff[i] == nil then
			diff[i] = {}
		end
		diff[i].now = v
	end
	for i, v in prev do
		if now[i] == v then
			continue
		end
		if diff[i] == nil then
			diff[i] = {}
		end
		diff[i].prev = v
	end
	return diff
end


local function datastore_replicate_get_diff(name: string, player: Player, key: string): diff
	local datastore = datastores[name]
	if datastore == nil then
		error(`No datastore found by name {name}!`)
	end
	local last = datastore.last_replicated
	local cur = datastore_get(name, player, key)
	local diff = diff_generate(last, cur)
	datastore.last_replicated = table.clone(cur)
	return diff
end


local profiles = {}

datastore_create("Plots", {
	layers = {}
})
datastore_create("Data", {
	currency = 0
})

function Data.load_plot(player)
	return datastore_get("Plots", player, `plot_{player.UserId}`)
end


function Data.load_data(player)
	return datastore_get("Data", player, `data_{player.UserId}`)
end


function Data.replicate_data(player)
	local diff: diff = datastore_replicate_get_diff("Data", player, `data_{player.UserId}`)
	if diff.currency then
		replicatedStorage.Remotes.StatEvent:FireClient(player, "currency", diff.currency.now)
	end
end


return true