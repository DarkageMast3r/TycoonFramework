--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Asset = require(common.Asset.Asset)


function Asset.set_fetch(set, key)
	return set[Asset.set_key_resolve(set, key)]
end


function Asset.set_key_resolve(set, key)
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


function Asset.set_append(set, items)
	for i, v in items do
		set[i:lower()] = v
	end
end


function Asset.set_append_from_folder(set, folder)
	for _, instance in folder:GetChildren() do
		set[instance.Name:lower()] = instance :: any
	end
end


return true