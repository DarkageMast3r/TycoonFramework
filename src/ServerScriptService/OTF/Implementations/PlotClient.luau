--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = script.Parent.Parent.Contracts
local common = replicatedStorage.OTF.Common
local Plot = require(common.Plot)
local Asset = require(common.Asset.Asset)
local Position = require(common.Data.Position)

local layers = {}

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
	for i, layer in new.layers_computed do
		layer.assets = old.layers[i].assets or layer.assets
		layer.assets_built = old.layers[i].assets_built or {}
		layer.assets_models = old.layers[i].assets_models or {}
	end
end


local function cell_update(
	back: {[string]: Plot.gridlayer},
	front: {[string]: Plot.gridlayer},
	pos: Position.position,
	dirty: {Position.position}
)
	for layerName, layer in back do
		local assetName = Plot.gridlayer_get_asset(layer, pos)
		Plot.gridlayer_set_asset(front[layerName], pos, assetName)
	end

	local pos_opposite = Position.translate(pos, 1, 0, 0, 2)
	local asset = Plot.gridlayer_get_asset(back.wall_inner, pos)
	local asset_opposite = Plot.gridlayer_get_asset(back.wall_inner, pos_opposite)
	if asset:find("Window") or asset_opposite:find("Window") then
		local asset1 = Plot.gridlayer_get_asset(back.wall_outer, pos)
		if not asset1:find("Window") then
			Plot.gridlayer_set_asset(front.wall_outer, pos, asset1 .. ".Window")
			table.insert(dirty, pos)
		end
		local asset2 = Plot.gridlayer_get_asset(back.wall_outer, pos_opposite)
		if not asset2:find("Window") then
			Plot.gridlayer_set_asset(front.wall_outer, pos_opposite, asset2 .. ".Window")
			table.insert(dirty, pos_opposite)
		end
	else
		local asset1 = Plot.gridlayer_get_asset(back.wall_outer, pos)
		if asset1:find("Window") then
			Plot.gridlayer_set_asset(front.wall_outer, pos, asset1:split(".Window")[1])
			table.insert(dirty, pos)
		end
		local asset2 = Plot.gridlayer_get_asset(back.wall_outer, pos_opposite)
		if asset2:find("Window") then
			Plot.gridlayer_set_asset(front.wall_outer, pos_opposite, asset2:split(".Window")[1])
			table.insert(dirty, pos_opposite)
		end
	end

	if asset:find("DoorSingle") or asset_opposite:find("DoorSingle") then
		local asset1 = Plot.gridlayer_get_asset(back.wall_outer, pos)
		if not asset1:find("DoorSingle") then
			Plot.gridlayer_set_asset(front.wall_outer, pos, asset1 .. ".DoorSingle")
			table.insert(dirty, pos)
		end
		local asset2 = Plot.gridlayer_get_asset(back.wall_outer, Position.translate(pos, 1, 0, 0, 2))
		if not asset2:find("DoorSingle") then
			Plot.gridlayer_set_asset(front.wall_outer, Position.translate(pos, 1, 0, 0, 2), asset2 .. ".DoorSingle")
			table.insert(dirty, pos_opposite)
		end
	else
		local asset1 = Plot.gridlayer_get_asset(back.wall_outer, pos)
		if asset1:find("DoorSingle") then
			Plot.gridlayer_set_asset(front.wall_outer, pos, asset1:split(".DoorSingle")[1])
			table.insert(dirty, pos)
		end
		local asset2 = Plot.gridlayer_get_asset(back.wall_outer, pos_opposite)
		if asset2:find("DoorSingle") then
			Plot.gridlayer_set_asset(front.wall_outer, pos_opposite, asset2:split(".DoorSingle")[1])
			table.insert(dirty, pos_opposite)
		end
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
					Plot.update_push({
						pos = Vector3.new(x-1, layer.height, z-1),
						rot = rot,
						plot = p.folder
					})
				end
			end
		end
	end
end


function Plot.build(p)
	if Plot.allPlots[p.folder] == nil then
		Plot.allPlots[p.folder] = p
		push_update_all(p)
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
		local idx = Plot.layers.center.get_index(p, pos.pos.X, pos.pos.Z, 0)
		try_build(gridlayer, destination, pos, idx)
	end,
	resize = function(src, from, to)
		local new = table.create(to.X * to.Y, "")
		for x = 0, math.min(from.X, to.X) - 1 do
			for z = 0, math.min(from.Y, to.Y) - 1 do
				local i = x + z * from.X + 1
				local i2 = x + z * to.X + 1
				new[i2] = src[i] or ""
			end
		end
		return new
	end
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
		for rot = 0, 3 do
			local idx = Plot.layers.edge.get_index(p, pos.pos.X, pos.pos.Z, rot)
			try_build(gridlayer, destination, {
				pos = pos.pos,
				rot = rot,
				plot = pos.plot
			}, idx)
		end
	end,
	resize = function(src, from, to)
		local new = table.create(to.X * to.Y * 4, "")
		for x = 0, math.min(from.X, to.X) - 1 do
			for z = 0, math.min(from.Y, to.Y) - 1 do
				for rot = 0, 3 do
					local i = (x + z * from.X) * 4 + rot + 1
					local i2 = (x + z * to.X) * 4 + rot + 1
					new[i2] = src[i] or ""
				end
			end
		end
		return new
	end
}

return true