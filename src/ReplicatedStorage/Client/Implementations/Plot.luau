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
	{
		include = {
			floor = {
				[{0, 0, 0, 0}] = "Wood"
			}
		},
		exclude = {},
		modifier = "Trim",
		layer = "wall_outer"
	},
	{
		include = {
			floor = {
				[{0, 0, 0, 1}] = "Wood"
			}
		},
		exclude = {},
		modifier = "Trim",
		layer = "wall_outer"
	},
	{
		include = {
			floor = {
				[{0, 0, 0, 2}] = "Wood"
			}
		},
		exclude = {},
		modifier = "Trim",
		layer = "wall_outer"
	},
	{
		include = {
			floor = {
				[{0, 0, 0, 3}] = "Wood"
			}
		},
		exclude = {},
		modifier = "Trim",
		layer = "wall_outer"
	},
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
	},
	{
		include = {
			wall_inner = {
				[{0, 0, 0, 0}] = "Window"
			}
		},
		exclude = {},
		modifier = "Window",
		layer = "wall_outer"
	},
	{
		include = {
			wall_inner = {
				[{1, 0, 0, 2}] = "Window"
			}
		},
		exclude = {},
		modifier = "Window",
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


local function transformation_rule_get_positions(rule: transformation, pos: position.position, result: {[string]: {position.position}})
	result[rule.layer] = result[rule.layer] or {}
	table.insert(result[rule.layer], pos)

	for layerName, rules in rule.include do
		result[layerName] = result[layerName] or {}
		for offset in rules do
			local newPos = position.translate(pos, 0, 0, 0, -offset[4])
			newPos = position.translate(newPos, -offset[1], -offset[2], -offset[3], 0)
			table.insert(result[layerName], newPos)
			table.insert(result[rule.layer], newPos)
		end
	end

	for layerName, rules in rule.exclude do
		result[layerName] = result[layerName] or {}
		for offset in rules do
			local newPos = position.translate(pos, 0, 0, 0, -offset[4])
			newPos = position.translate(newPos, -offset[1], -offset[2], -offset[3], 0)
			table.insert(result[layerName], newPos)
			table.insert(result[rule.layer], newPos)
		end
	end
end


local function transformation_rules_get_positions(pos: position.position, result: {[string]: {position.position}})
	for _, rule in transformation_rules do
		transformation_rule_get_positions(rule, pos, result)
	end
end


local function cell_update_single(
	rule: transformation,
	back: {[string]: plot.gridlayer},
	front: {[string]: plot.gridlayer},
	pos: position.position
)
end


local function cell_update(
	back: {[string]: plot.gridlayer},
	front: {[string]: plot.gridlayer},
	pos: position.position,
	dirty: {position.position}
)
	local positions_to_check = {}
	transformation_rules_get_positions(pos, positions_to_check)
	for layerName, positions in positions_to_check do
		for _, newPos in positions do
			plot.gridlayer_set_asset(front[layerName], newPos, plot.gridlayer_get_asset(back[layerName], newPos))
			table.insert(dirty, newPos)
		end
	end

	for layerName, positions in positions_to_check do
		for _, newPos in positions do
			local assets_staged = {}
			for _, rule in transformation_rules do
				if cell_matches_transformation_rule(back, newPos, rule) then
					local asset = assets_staged[rule.layer] or plot.gridlayer_get_asset(back[rule.layer], newPos)
					if not asset:find(rule.modifier) and asset ~= "" then
						assets_staged[rule.layer] = asset .. "." .. rule.modifier
					end
				end
			end
			for layer_name, asset in assets_staged do
				plot.gridlayer_set_asset(front[layer_name], newPos, asset)
			end
		end
	end
end


local function cell_init(
	back: {[string]: plot.gridlayer},
	front: {[string]: plot.gridlayer},
	pos: position.position
)
	for layerName in back do	
		local asset = plot.gridlayer_get_asset(back[layerName], pos)
		plot.gridlayer_set_asset(front[layerName], pos, asset)
	end
	local assets_staged = {}
	for _, rule in transformation_rules do
		if cell_matches_transformation_rule(back, pos, rule) then
			local asset = assets_staged[rule.layer] or plot.gridlayer_get_asset(back[rule.layer], pos)
			if asset ~= "" and not asset:find(rule.modifier) then
				assets_staged[rule.layer] = asset .. "." .. rule.modifier
			end
		end
	end
	for layer_name, asset in assets_staged do
		plot.gridlayer_set_asset(front[layer_name], pos, asset)
	end
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


local function plot_init(p: plot.plot)
	plot.allPlots[p.folder] = p
	local layers_by_height_front = {}
	local layers_by_height_back = {}
	for _, layer in p.layers_computed do
		local height = layer.height
		layers_by_height_front[height] = layers_by_height_front[height] or {}
		layers_by_height_front[height][layer.name] = layer
	end
	for _, layer in p.layers do
		local height = layer.height
		layers_by_height_back[height] = layers_by_height_back[height] or {}
		layers_by_height_back[height][layer.name] = layer
	end
	local models = p.folder:FindFirstChild("Models")
	if models == nil then
		return
	end

	for height, front in layers_by_height_front do
		for x = 1, p.size.X do
			for z = 1, p.size.Y do
				for rot = 0, 3 do
					local pos = {
						pos = Vector3.new(x-1, height, z-1),
						rot = rot,
						plot = p.folder
					}
					
					cell_init(layers_by_height_back[height], front, pos)
					for _, layer in front do
						plot.layers[layer.type].build_cell(p, layer, pos, models)
					end
				end
			end
		end
	end
end


function plot.build(p)
	if plot.allPlots[p.folder] == nil then
		plot_init(p)
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