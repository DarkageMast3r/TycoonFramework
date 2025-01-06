--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local asset = require(common.Asset.Asset)
local plot = require(common.Plot)
local config = require(common.Config)
local position = require(common.Data.Position)


function asset.set_uninteractable(model)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
	end
end


function asset.create_by_name(name)
	if name == "" then
		return Instance.new("Model")
	end
	local asset = asset.set_fetch(asset.assets, name)
	local created = asset:Clone()
	for _, part in created:GetDescendants() do
		if part:IsA("BasePart") then
			if part.CollisionGroup == "Actor" then
				part.Transparency = 1
			end
		end
	end
	
	return created
end


function asset.without_modifiers(name)
	local idx = name:find("%[")
	if idx == nil then
		return name
	end
	return name:sub(idx, -2)
end


function asset.modifier_add(name, modifier)
	local raw = asset.without_modifiers(name)
	local modifiers = asset.modifier_get(modifier)
	modifiers[modifier] = true
	local modifier_list = {}
	for modifier in modifiers do
		table.insert(modifier_list, modifier)
	end
	return `{raw}[{table.concat(modifier_list, ";")}]`
end


function asset.modifier_remove(name, modifier)
	local raw = asset.without_modifiers(name)
	local modifiers = asset.modifier_get(modifier)
	modifiers[modifier] = nil
	local modifier_list = {}
	for modifier in modifiers do
		table.insert(modifier_list, modifier)
	end
	return `{raw}[{table.concat(modifier_list, ";")}]`
end


function asset.modifier_get(name)
	local idx = name:find("%[")
	if idx == nil then
		return {}
	end

	local modifiers = name:sub(idx, -2)
	local modifier_list = modifiers:split(";")
	if modifier_list[1] == "" then
		return {}
	end
	local result = {}
	for _, modifier in modifier_list do
		result[modifier] = true
	end
	return result
end


function asset.resolve_type(name)
	local frag = name:split(".")
	return frag[1]:lower()
end


function asset.move_to(model, pos)
	model:PivotTo(position.object_to_world_cf(pos))
end


return true