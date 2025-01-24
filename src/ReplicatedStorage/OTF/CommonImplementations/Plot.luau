--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local common = replicatedStorage.OTF.Common
local Plot = require(common.Plot)
local Position = require(common.Data.Position)

local plot_queries: {
	[Folder]: {
		[string]: { -- Layer
			[string]: {Position.position} -- Query -> {position}
		}
	}	
} = {}
local layers = {}
Plot.allPlots = {}


function Plot.get_by_folder(folder)
	if folder == nil then
		return nil
	end
	return Plot.allPlots[folder]
end


function Plot.get_by_owner(owner)
	local found = {}
	for _, plot in Plot.allPlots do
		if plot.owner == owner then
			table.insert(found, plot)
		end
	end
	return found
end


function Plot.get_unclaimed()
	local found = {}
	for _, plot in Plot.allPlots do
		if plot.owner == nil then
			table.insert(found, plot)
		end
	end
	return found
end


function Plot.update_push(pos)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end

	table.insert(p.updates, pos)
end


function Plot.gridlayer_get(plot, name, height)
	for _, layer in plot.layers do
		if layer.height == height and layer.name == name then
			return layer
		end
	end
	return nil
end


function Plot.get_asset(pos, layer)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return ""
	end
	local gridlayer = Plot.gridlayer_get(p, layer, pos.pos.Y)
	if gridlayer == nil then
		return ""
	end
	return Plot.gridlayer_get_asset(gridlayer, pos)
end


function Plot.gridlayer_get_computed(plot, name, height)
	for _, layer in plot.layers_computed do
		if layer.height == height and layer.name == name then
			return layer
		end
	end
	return nil
end


function Plot.gridlayer_get_asset(gridlayer, pos)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return ""
	end
	local idx = Plot.layers[gridlayer.type].get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	return gridlayer.assets[idx] or ""
end


local function plotquery_position_update(p: Plot.plot, pos: Position.position, layerName: string, asset: string, insert: boolean)
	if plot_queries[p.folder] == nil then
		return
	end
	if plot_queries[p.folder][layerName] == nil then
		return
	end
	for assetQuery, allQueries in plot_queries[p.folder][layerName] do
		if not asset:find(assetQuery) then
			continue
		end
	
		local idx: number? = nil
		for i, pos2 in allQueries do
			if pos2.pos == pos.pos and pos2.rot == pos.rot then
				idx = i
			end
		end
		if insert and idx == nil then
			table.insert(allQueries, pos)
		elseif not insert and idx ~= nil then
			table.remove(allQueries, idx)
		end
	end
end


function Plot.gridlayer_set_asset(gridlayer, pos, asset)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return false
	end
	local idx = Plot.layers[gridlayer.type].get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	if gridlayer.assets[idx] == nil then
		return false
	end
	plotquery_position_update(p, pos, gridlayer.name, gridlayer.assets[idx], false)
	gridlayer.assets[idx] = asset
	plotquery_position_update(p, pos, gridlayer.name, asset, true)
	return true
end


function Plot.gridlayer_get_metadata(gridlayer, pos): any
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return nil
	end
	local idx = Plot.layers[gridlayer.type].get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	return gridlayer.metadata[idx]
end


function Plot.gridlayer_set_metadata(gridlayer, pos, metadata)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end
	local idx = Plot.layers[gridlayer.type].get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	gridlayer.metadata[idx] = metadata
end


function Plot.gridlayer_get_collision(gridlayer, pos)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return false
	end
	local layer = Plot.layers[gridlayer.type]
	local idx = layer.get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	return gridlayer.collision[idx] or false
end


function Plot.gridlayer_set_collision(gridlayer, pos, collision)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end
	local layer = Plot.layers[gridlayer.type]
	local idx = layer.get_index(p, pos.pos.X, pos.pos.Z, pos.rot)
	if gridlayer.collision[idx] == nil then
		return
	end
	gridlayer.collision[idx] = collision
end


function Plot.collisionmesh_collides(pos, mesh)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return false
	end

	local collides = false
	local mayBePlaced = true
	for layer, data in mesh do
		for _, node in data do
			local pos2 = node.pos.pos
			local relpos = Position.translate(pos, pos2.Z, pos2.X, pos2.Y, node.pos.rot)
			local gridlayer = Plot.gridlayer_get(p, layer, relpos.pos.Y)
			if gridlayer == nil then
				continue
			end
			local filled = Plot.gridlayer_get_collision(gridlayer, relpos)
			if node.mode == 1 then
				if filled then
					collides = true
				end
			elseif node.mode == 2 then
				if not filled then
					mayBePlaced = false
				end
			else
				warn(`Mode {node.mode} unhandled!`)
			end
		end
	end
	return collides or not mayBePlaced
end


function Plot.collisionmesh_place(pos, mesh)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return
	end
	for layer, data in mesh do
		for _, node in data do
			local pos2 = node.pos.pos
			local relpos = Position.translate(pos, pos2.Z, pos2.X, pos2.Y, node.pos.rot)
			local gridlayer = Plot.gridlayer_get(p, layer, relpos.pos.Y)
			if gridlayer == nil then
				continue
			end
			Plot.gridlayer_set_collision(gridlayer, relpos, true)
		end
	end
end


function Plot.collisionmesh_remove(pos, mesh)
	local p = Plot.get_by_folder(pos.plot)
	if p == nil then
		return false
	end

	for layer, data in mesh do
		for _, node in data do
			local pos2 = node.pos.pos
			local relpos = Position.translate(pos, pos2.Z, pos2.X, pos2.Y, node.pos.rot)
			local gridlayer = Plot.gridlayer_get(p, layer, relpos.pos.Y)
			if gridlayer == nil then
				continue
			end
			Plot.gridlayer_set_collision(gridlayer, relpos, false)
		end
	end
end


function Plot.asset_seek(p, layerName, assetName)
	if not plot_queries[p.folder] then
		plot_queries[p.folder] = {}
	end
	if not plot_queries[p.folder][layerName] then
		plot_queries[p.folder][layerName] = {}
	end
	if plot_queries[p.folder][layerName][assetName] then
		return plot_queries[p.folder][layerName][assetName]
	end
	
	local found = {}
	for _, gridlayer in p.layers do
		if gridlayer.name ~= layerName then
			continue
		end
		local layer = Plot.layers[gridlayer.type]
		for i, asset in gridlayer.assets do
			if asset:find(assetName) then
				table.insert(found, layer.get_position(p, i))
			end
		end
	end
	
	plot_queries[p.folder][layerName][assetName] = found
	return found
end


return true