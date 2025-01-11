--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = script.Parent.Parent.Contracts
local common = replicatedStorage.Common
local plot = require(common.Plot)
local asset = require(common.Asset.Asset)
local position = require(common.Data.Position)

local layers = {}

local function try_build(layer: plot.gridlayer, destination: Instance, pos: position.position, idx: number)
	local asset_name = asset.set_key_resolve(asset.assets, layer.assets[idx])
	if layer.assets_built[idx] == asset_name then
		return
	end
	layer.assets_built[idx] = asset_name

	local existingmodel = layer.assets_models[idx]
	if existingmodel then
		existingmodel:Destroy()
		layer.assets_models[idx] = nil
	end

	local created = asset.create_by_name(layer.assets[idx])

	asset.move_to(created, pos)
	layer.assets_models[idx] = created
	created.Parent = destination
end


local function plot_merge(old: plot.plot, new: plot.plot)
	for i, layer in new.layers do
		layer.assets_built = old.layers[i].assets_built or {}
		layer.assets_models = old.layers[i].assets_models or {}
	end
	--[[
	for i, layer in new.layers_computed do
		layer.assets = old.layers_computer[i].assets or layer.assets
		layer.assets_built = old.layers_computer[i].assets_built or {}
		layer.assets_models = old.layers_computer[i].assets_models or {}
	end
	--]]
end

type transformation = {
	include: {
		[string]: {
			[{number}]: string
		}
	},
	exclude: {
		[string]: {
			[{number}]: string
		}
	},
	modifier: string,
	layer: string
}


local transformation_rules: {transformation} = {
	--[[
	{
		include = {
			wall_inner = {
				[{0, 0, 0, 0}] = "Window",
				[{1, 0, 0, 2}] = "Window"
			}
		},
		exclude = {},
		modifier = "Window",
		layer = "wall_outer"
	},]]
	{
		include = {
			wall_inner = {
				[{0, 0, 0, 0}] = "DoorSingle"
			}
		},
		exclude = {},
		modifier = "DoorSingle",
		layer = "wall_outer"
	},
	{
		include = {
			wall_inner = {
				[{1, 0, 0, 2}] = "DoorSingle"
			}
		},
		exclude = {},
		modifier = "DoorSingle",
		layer = "wall_outer"
	}
}


local function cell_matches_transformation_rule(
	layers: {[string]: plot.gridlayer},
	pos: position.position,
	transformation: transformation
): boolean
	local allIncluded = true
	local anyExcluded = false
	for layerName, rules in transformation.include do
		for offset, name in rules do
			local newPos = position.translate(pos, offset[1], offset[2], offset[3], offset[4])
			local asset = plot.gridlayer_get_asset(layers[layerName], newPos)
			allIncluded = allIncluded and asset:find(name)
		end
	end
	for layerName, rules in transformation.exclude do
		for offset, name in rules do
			local newPos = position.translate(pos, offset[1], offset[2], offset[3], offset[4])
			local asset = plot.gridlayer_get_asset(layers[layerName], newPos)
			anyExcluded = anyExcluded or not asset:find(name)
		end
	end
	return allIncluded
end


local function cell_update(
	back: {[string]: plot.gridlayer},
	front: {[string]: plot.gridlayer},
	pos: position.position,
	dirty: {position.position}
)
	local pos_opposite = position.translate(pos, 1, 0, 0, 2)
	for _, rule in transformation_rules do
		for layerName, rules in rule.include do
			for offset in rules do
				local newPos = position.translate(pos, 0, 0, 0, -offset[4])
				newPos = position.translate(newPos, offset[1], offset[2], offset[3], 0)
				plot.gridlayer_set_asset(front[layerName], newPos, plot.gridlayer_get_asset(back[layerName], newPos))
				table.insert(dirty, newPos)
			end
		end
		for layerName, rules in rule.exclude do
			for offset in rules do
				local newPos = position.translate(pos, 0, 0, 0, -offset[4])
				newPos = position.translate(newPos, offset[1], offset[2], offset[3], 0)
				plot.gridlayer_set_asset(front[layerName], newPos, plot.gridlayer_get_asset(back[layerName], newPos))
				table.insert(dirty, newPos)
			end
		end
	end

	for _, rule in transformation_rules do
		local asset = plot.gridlayer_get_asset(back[rule.layer], pos)
		plot.gridlayer_set_asset(front[rule.layer], pos, asset)
		table.insert(dirty, pos)
	end
	for _, rule in transformation_rules do
		if cell_matches_transformation_rule(back, pos, rule) then
			local asset = plot.gridlayer_get_asset(back[rule.layer], pos)
			plot.gridlayer_set_asset(front[rule.layer], pos, asset .. "." .. rule.modifier)
		end
	end

	local asset = plot.gridlayer_get_asset(back.wall_inner, pos)
	local asset_opposite = plot.gridlayer_get_asset(back.wall_inner, pos_opposite)
	if asset:find("Window") or asset_opposite:find("Window") then
		local asset1 = plot.gridlayer_get_asset(back.wall_outer, pos)
		if not asset1:find("Window") then
			plot.gridlayer_set_asset(front.wall_outer, pos, asset1 .. ".Window")
			table.insert(dirty, pos)
		end
		local asset2 = plot.gridlayer_get_asset(back.wall_outer, pos_opposite)
		if not asset2:find("Window") then
			plot.gridlayer_set_asset(front.wall_outer, pos_opposite, asset2 .. ".Window")
			table.insert(dirty, pos_opposite)
		end
	end

	--[[
	if asset:find("DoorSingle") or asset_opposite:find("DoorSingle") then
		local asset1 = plot.gridlayer_get_asset(back.wall_outer, pos)
		if not asset1:find("DoorSingle") then
			plot.gridlayer_set_asset(front.wall_outer, pos, asset1 .. ".DoorSingle")
			table.insert(dirty, pos)
		end
		local asset2 = plot.gridlayer_get_asset(back.wall_outer, position.translate(pos, 1, 0, 0, 2))
		if not asset2:find("DoorSingle") then
			plot.gridlayer_set_asset(front.wall_outer, position.translate(pos, 1, 0, 0, 2), asset2 .. ".DoorSingle")
			table.insert(dirty, pos_opposite)
		end
	end
	]]
end


function plot.update_execute_all(p)
	local dirty = {}
	for _, update in p.updates do
		local height = update.pos.Y
		local back = {}
		local front = {}
		for _, layer in p.layers do
			if layer.height == update.pos.Y then
				back[layer.name] = layer
			end
		end
		for _, layer in p.layers_computed do
			if layer.height == update.pos.Y then
				front[layer.name] = layer
			end
		end
		cell_update(back, front, update, dirty)
	end
	for _, pos in dirty do
		plot.update_push(pos)
	end
end


local function push_update_all(p)
	local heights = {}
	for _, layer in p.layers do
		if heights[layer.height] then
			continue
		end

		heights[layer.height] = true
		for x = 1, p.size.X do
			for z = 1, p.size.Y do
				for rot = 0, 3 do
					plot.update_push({
						pos = Vector3.new(x-1, layer.height, z-1),
						rot = rot,
						plot = p.folder
					})
				end
			end
		end
	end
end


function plot.build(p)
	if plot.allPlots[p.folder] == nil then
		plot.allPlots[p.folder] = p
		push_update_all(p)
	end
	plot_merge(plot.allPlots[p.folder], p)
	
	local models = p.folder:FindFirstChild("Models")
	if models == nil then
		return
	end
	plot.update_execute_all(p)
	
	for _, pos in p.updates do
		for _, layer in p.layers_computed do
			if layer.height == pos.pos.Y then
				plot.layers[layer.type].build_cell(p, layer, pos, models)
			end
		end
	end
	table.clear(p.updates)
end


plot.layers.center = {
	get_index = function(p, x, z, rotation)
		return x + z * p.size.X + 1
	end,
	get_position = function(p, idx)
		idx -= 1
		local x = idx % p.size.X
		idx = math.floor(idx / p.size.X)
		local z = idx
		return {
			pos = Vector3.new(x, 0, z),
			rot = 0,
			plot = p.folder
		}
	end,
	build = function(p, gridlayer, destination)
		for x = 0, p.size.X - 1 do
			for z = 0, p.size.Y - 1 do
				local idx = plot.layers.center.get_index(p, x, z, 0)
				try_build(gridlayer, destination, {
					pos = Vector3.new(x, gridlayer.height, z),
					rot = 0,
					plot = p.folder
				}, idx)
			end
		end
	end,
	build_cell = function(p, gridlayer, pos, destination)
		if pos.pos.X < 0 or pos.pos.Z < 0 or pos.pos.X >= p.size.X or pos.pos.Z >= p.size.Y then
			return
		end
		local idx = plot.layers.center.get_index(p, pos.pos.X, pos.pos.Z, 0)
		try_build(gridlayer, destination, pos, idx)
	end,
	resize = function(src, from, to) return src end
}

plot.layers.edge = {
	get_index = function(p, x, z, rotation)
		return (x + z * p.size.X) * 4 + rotation + 1
	end,
	get_position = function(p, idx)
		idx -= 1
		local rot = idx % 4
		idx = math.floor(idx / 4)
		local x = idx % p.size.X
		idx = math.floor(idx / p.size.X)
		local z = idx
		return {
			pos = Vector3.new(x, 0, z),
			rot = rot,
			plot = p.folder
		}
	end,
	build = function(p, gridlayer, destination)
		for x = 0, p.size.X - 1 do
			for z = 0, p.size.Y - 1 do
				for rot = 0, 3 do
					local idx = plot.layers.edge.get_index(p, x, z, rot)
					try_build(gridlayer, destination, {
						pos = Vector3.new(x, gridlayer.height, z),
						rot = rot,
						plot = p.folder
					}, idx)
				end
			end
		end
	end,
	build_cell = function(p, gridlayer, pos, destination)
		if pos.pos.X < 0 or pos.pos.Z < 0 or pos.pos.X >= p.size.X or pos.pos.Z >= p.size.Y then
			return
		end
		for rot = 0, 3 do
			local idx = plot.layers.edge.get_index(p, pos.pos.X, pos.pos.Z, rot)
			try_build(gridlayer, destination, {
				pos = pos.pos,
				rot = rot,
				plot = pos.plot
			}, idx)
		end
	end,
	resize = function(src, from, to) return src end
}

return true