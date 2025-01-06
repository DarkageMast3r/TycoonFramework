--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local asset = require(common.Asset.Asset)
local plot = require(common.Plot)
local config = require(common.Config)
local position = require(common.Data.Position)



function asset.set_fetch(set, key)
	return set[asset.set_key_resolve(set, key)]
end

function asset.set_key_resolve(set, key)
	local originalKey = key
	key = key:lower()
	if set[key] then
		return key
	end
	while set[key] == nil and key ~= "" do
		local frag = key:split(".")
		table.remove(frag, #frag)
		key = table.concat(frag, ".")
	end
	if set[key] == nil then
		error(`Could not resolve key {originalKey}!`)
	end
	return key
end

function asset.set_append(set, items)
	for i, v in items do
		set[i:lower()] = v
	end
end

function asset.set_append_from_folder(set, folder)
	for _, instance in folder:GetChildren() do
		set[instance.Name:lower()] = instance :: any
	end
end


return true