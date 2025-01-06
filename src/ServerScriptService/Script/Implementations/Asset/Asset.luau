--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local asset = require(common.Asset.Asset)
local plot = require(common.Plot)


function asset.create_by_name(name)
	if name == "" then
		return Instance.new("Model")
	end
	name = asset.set_key_resolve(asset.assets, name)
	local asset = replicatedStorage.Assets:WaitForChild(name)
	return asset:Clone()
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
	local p = plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end
	model:PivotTo(
		p.origin:ToWorldSpace(
			CFrame.new(
				(pos.pos.X - p.size.X / 2 + 0.5) * 4,
				pos.pos.Y * 4,
				(pos.pos.Z - p.size.Y / 2 + 0.5) * 4
			)
		) * CFrame.Angles(0, pos.rot * math.pi * 0.5, 0)
	)
end


local collisionmesh_cache: {[string]: asset.collisionmesh} = {}


local function collisionmesh_parse(name: string): asset.collisionmesh
	local layers = {}
	local asset = asset.set_fetch(asset.assets, name)
	for _, child in asset:GetChildren() do
		if not child:IsA("BoolValue") then
			continue
		end

		local x = child:GetAttribute("x") :: number
		local z = child:GetAttribute("z") :: number
		local rot = child:GetAttribute("rot") :: number
		local layer = child:GetAttribute("layer") :: string
		if layers[layer] == nil then
			layers[layer] = {}
		end

		table.insert(layers[layer], {
			pos = {
				pos = Vector3.new(x, 0, z),
				rot = rot
			},
			mode = child.Value and 1 or 2
		})
	end
	return layers
end


function asset.collisionmesh_get(name)
	if name == "" then
		return {}
	end
	
	name = asset.set_key_resolve(asset.assets, name)
	collisionmesh_cache[name] = collisionmesh_cache[name] or collisionmesh_parse(name)
	return collisionmesh_cache[name]
end


return true