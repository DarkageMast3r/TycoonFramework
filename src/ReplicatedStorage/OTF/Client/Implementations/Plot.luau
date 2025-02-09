--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = script.Parent.Parent.Contracts
local common = replicatedStorage.OTF.Common
local Plot = require(common.Plot)
local Asset = require(common.Asset.Asset)
local Position = require(common.Data.Position)

local layers = {}


function Plot.claim(plot, player)
	plot.owner = player
	print(`{player.Name} claimed plot {plot.folder:GetFullName()}`)
	return true
end


function Plot.unclaim(plot, player)
	plot.owner = nil
	print(`Unclaimed plot {plot.folder:GetFullName()}`)
	return true
end


local function try_build(layer: Plot.gridlayer, destination: Instance, pos: Position.position, idx: number)
	local asset_name = Asset.set_key_resolve(Asset.assets, layer.assets[idx])
	if layer.assets_built[idx] == asset_name then
		return
	end
	layer.assets_built[idx] = asset_name

	local existingmodel = layer.assets_models[idx]
	if existingmodel then
		existingmodel:Destroy()
		layer.assets_models[idx] = nil
	end

	local created = Asset.create_by_name(layer.assets[idx])

	Asset.move_to(created, pos)
	layer.assets_models[idx] = created
	created.Parent = destination
end


local function plot_merge(old: Plot.plot, new: Plot.plot)
	for i, layer in new.layers do
		layer.assets_built = old.layers[i].assets_built or {}
		layer.assets_models = old.layers[i].assets_models or {}
	end
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
	layers: {[string]: Plot.gridlayer},
	pos: Position.position,
	transformation: transformation
): boolean
	local allIncluded = true
	local anyExcluded = false
	for layerName, rules in transformation.include do
		for offset, name in rules do
			local newPos = Position.translate(pos, offset[1], offset[2], offset[3], offset[4])
			local asset = Plot.gridlayer_get_asset(layers[layerName], newPos)
			allIncluded = allIncluded and asset:find(name) ~= nil
		end
	end
	for layerName, rules in transformation.exclude do
		for offset, name in rules do
			local newPos = Position.translate(pos, offset[1], offset[2], offset[3], offset[4])
			local asset = Plot.gridlayer_get_asset(layers[layerName], newPos)
			anyExcluded = anyExcluded or asset:find(name) == nil
		end
	end
	return allIncluded
end


local function transformation_rule_get_positions(rule: transformation, pos: Position.position, result: {[string]: {Position.position}})
	result[rule.layer] = result[rule.layer] or {}
	table.insert(result[rule.layer], pos)

	for layerName, rules in rule.include do
		result[layerName] = result[layerName] or {}
		for offset in rules do
			local newPos = Position.translate(pos, 0, 0, 0, -offset[4])
			newPos = Position.translate(newPos, -offset[1], -offset[2], -offset[3], 0)
			table.insert(result[layerName], newPos)
			table.insert(result[rule.layer], newPos)
		end
	end

	for layerName, rules in rule.exclude do
		result[layerName] = result[layerName] or {}
		for offset in rules do
			local newPos = Position.translate(pos, 0, 0, 0, -offset[4])
			newPos = Position.translate(newPos, -offset[1], -offset[2], -offset[3], 0)
			table.insert(result[layerName], newPos)
			table.insert(result[rule.layer], newPos)
		end
	end
end


local function transformation_rules_get_positions(pos: Position.position, result: {[string]: {Position.position}})
	for _, rule in transformation_rules do
		transformation_rule_get_positions(rule, pos, result)
	end
end


local function cell_update(
	back: {[string]: Plot.gridlayer},
	front: {[string]: Plot.gridlayer},
	pos: Position.position,
	dirty: {Position.position}
)
	local positions_to_check = {}
	transformation_rules_get_positions(pos, positions_to_check)
	for _, positions in positions_to_check do
		for _, newPos in positions do
			for layerName in back do
				Plot.gridlayer_set_asset(front[layerName], newPos, Plot.gridlayer_get_asset(back[layerName], newPos))
			end
			table.insert(dirty, newPos)
		end
	end

	for layerName, positions in positions_to_check do
		for _, newPos in positions do
			local assets_staged = {}
			for _, rule in transformation_rules do
				if cell_matches_transformation_rule(back, newPos, rule) then
					local asset = assets_staged[rule.layer] or Plot.gridlayer_get_asset(back[rule.layer], newPos)
					if not asset:find(rule.modifier) and asset ~= "" then
						assets_staged[rule.layer] = asset .. "." .. rule.modifier
					end
				end
			end
			for layer_name, asset in assets_staged do
				Plot.gridlayer_set_asset(front[layer_name], newPos, asset)
			end
		end
	end
end


local function cell_init(
	back: {[string]: Plot.gridlayer},
	front: {[string]: Plot.gridlayer},
	pos: Position.position
)
	for layerName in back do	
		local asset = Plot.gridlayer_get_asset(back[layerName], pos)
		Plot.gridlayer_set_asset(front[layerName], pos, asset)
	end
	local assets_staged = {}
	for _, rule in transformation_rules do
		if cell_matches_transformation_rule(back, pos, rule) then
			local asset = assets_staged[rule.layer] or Plot.gridlayer_get_asset(back[rule.layer], pos)
			if asset ~= "" and not asset:find(rule.modifier) then
				assets_staged[rule.layer] = asset .. "." .. rule.modifier
			end
		end
	end
	for layer_name, asset in assets_staged do
		Plot.gridlayer_set_asset(front[layer_name], pos, asset)
	end
end


function Plot.update_execute_all(p)
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
		Plot.update_push(pos)
	end
end


local function plot_init(p: Plot.plot)
	Plot.allPlots[p.folder] = p
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
						Plot.layers[layer.type].build_cell(p, layer, pos, models)
					end
				end
			end
		end
	end
end


function Plot.build(p, reload)
	if Plot.allPlots[p.folder] == nil or reload then
		plot_init(p)
	end
	plot_merge(Plot.allPlots[p.folder], p)
	
	local models = p.folder:FindFirstChild("Models")
	if models == nil then
		return
	end
	Plot.update_execute_all(p)
	
	for _, pos in p.updates do
		for _, layer in p.layers_computed do
			if layer.height == pos.pos.Y then
				Plot.layers[layer.type].build_cell(p, layer, pos, models)
			end
		end
	end
	table.clear(p.updates)
end


Plot.layers.center = {
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
				local idx = Plot.layers.center.get_index(p, x, z, 0)
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
		local idx = Plot.layers.center.get_index(p, pos.pos.X, pos.pos.Z, 0)
		try_build(gridlayer, destination, pos, idx)
	end,
	resize = function(src, from, to) return src end
}

Plot.layers.edge = {
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
					local idx = Plot.layers.edge.get_index(p, x, z, rot)
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
			local idx = Plot.layers.edge.get_index(p, pos.pos.X, pos.pos.Z, rot)
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