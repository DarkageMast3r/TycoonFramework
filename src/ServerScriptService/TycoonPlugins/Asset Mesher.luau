--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local selection = game:GetService("Selection")
local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common

local Elements = require(contracts.UI.Elements)
local Asset = require(common.Asset.Asset)
local Config = require(common.Config)

local function part_cut_part(part: Part, cutter: Part)
	local bounds = {
		cutter.CFrame:PointToWorldSpace(cutter.Size * -0.5),
		cutter.CFrame:PointToWorldSpace(cutter.Size * 0.5)
	}
	local bounds_part = {
		part.CFrame:PointToWorldSpace(part.Size * -0.5),
		part.CFrame:PointToWorldSpace(part.Size * 0.5)
	}
	local min_part = bounds_part[1]:Min(bounds_part[2])
	local max_part = bounds_part[1]:Max(bounds_part[2])
	local min = bounds[1]:Min(bounds[2]):Min(max_part):Max(min_part)
	local max = bounds[1]:Max(bounds[2]):Min(max_part):Max(min_part)
	
	if max.X + 0.001 < max_part.X then
		local new = part:Clone()
		local p_max = max_part
		local p_min = Vector3.new(max.X, min_part.Y, min_part.Z)
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end
	if min.X - 0.001 > min_part.X then
		local new = part:Clone()
		local p_max = Vector3.new(min.X, max_part.Y, max_part.Z)
		local p_min = min_part
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end

	if max.Y + 0.001 < max_part.Y then
		local new = part:Clone()
		local p_max = Vector3.new(max.X, max_part.Y, max_part.Z)
		local p_min = Vector3.new(min.X, max.Y, min_part.Z)
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end
	if min.Y - 0.001 > min_part.Y then
		local new = part:Clone()
		local p_max = Vector3.new(max.X, min.Y, max_part.Z)
		local p_min = Vector3.new(min.X, min_part.Y, min_part.Z)
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end
	if max.Z + 0.001 < max_part.Z then
		local new = part:Clone()
		local p_max = Vector3.new(max.X, max.Y, max_part.Z)
		local p_min = Vector3.new(min.X, min.Y, max.Z)
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end
	if min.Z - 0.001 > min_part.Z then
		local new = part:Clone()
		local p_max = Vector3.new(max.X, max.Y, min.Z)
		local p_min = Vector3.new(min.X, min.Y, min_part.Z)
		new.Size = p_max - p_min
		new.CFrame = CFrame.new((p_max + p_min) / 2)
		new.Parent = part.Parent
	end
	
	part:Destroy()
end


local function model_cut_part(model: Model, cutter: Part)
	for _, part in model:GetChildren() do
		if part:IsA("Part") then
			part_cut_part(part, cutter)
		end
	end
end


local function model_cut_cutter(model: Model, cutter: Model)
	cutter:PivotTo(model.WorldPivot)
	for _, part in cutter:GetChildren() do
		if part:IsA("Part") then
			model_cut_part(model, part)
		end
	end
end


local function on_active()
	local created = {}
	for _, model in selection:Get() do
		local i = 0
		for _, cutter in replicatedStorage.Assets.Cutters:GetChildren() do
			i += 1
			local newModel = model:Clone()
			newModel.Name = `{model.Name}.{cutter.Name}`
			model_cut_cutter(newModel, cutter)
			newModel.Parent = model.Parent
			newModel:PivotTo(model.WorldPivot + model.WorldPivot:VectorToWorldSpace(Config.cell.size * Vector3.new(i, 0, 0)))
			table.insert(created, newModel)
		end
	end
	selection:Set(created)
end


return {
	type = "button",
	description = "Automatically generate predefined meshes",
	icon = 8740888472,
	on_active = on_active
}