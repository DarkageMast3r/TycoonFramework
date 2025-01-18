--!strict
local serverScriptService = game:GetService("ServerScriptService")
local pathfindingService = game:GetService("PathfindingService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local contracts = serverScriptService.Script.Contracts
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local plot = require(common.Plot)
local asset = require(common.Asset.Asset)
local data = require(contracts.Data)
local nodegraph = require(common.Data.Nodegraph)
local Tycoon = require(common.Game.Tycoon)


function plot.create_from_folder(folder)
	local valid, err = plot.is_valid_folder(folder)
	if not valid then
		error(err)
	end

	local grid = folder:WaitForChild("Grid") :: BasePart
	local p: plot.plot = {
		dirty = false,
		layers = {},
		folder = folder,
		origin = grid.CFrame,
		size = Vector2int16.new(grid.Size.X / 4, grid.Size.Z / 4),
		updates = {},
		layers_computed = {}
	}
	plot.allPlots[folder] = p
	return p
end


function plot.is_valid_folder(folder)
	local grid = folder:FindFirstChild("Grid")
	if not grid then
		return false, string.format("Folder %s is missing part Grid", folder:GetFullName())
	end
	if not grid:IsA("BasePart") then
		return false, string.format("Folder %s > Grid is not a part", folder:GetFullName())
	end
	if not folder:FindFirstChild("Models") then
		return false, string.format("Folder %s is missing folder Models", folder:GetFullName())
	end
	return true, ""
end


function plot.claim(p, player)
	if p.owner ~= nil then
		return false
	end
	plot.load(p, player)
	p.owner = player
	return true
end


function plot.unclaim(plot, player)
	if plot.owner ~= player then
		return false
	end
	plot.owner = nil
	-- TODO: Clear all built assets
	return true
end


function plot.gridlayer_attach(plot, type, name, height)
	local asset_count = 0
	if type == "edge" then
		asset_count = plot.size.X * plot.size.Y * 4
	elseif type == "center" then
		asset_count = plot.size.X * plot.size.Y
	else
		error("Unhandled layer type "..type)
	end
	table.insert(plot.layers, {
		type = type,
		name = name,
		height = height,
		collision = table.create(asset_count, false),
		assets = table.create(asset_count, ""),
		assets_built = {},
		assets_models = {},
		metadata = {}
	})
	table.insert(plot.layers_computed, {
		type = type,
		name = name,
		height = height,
		collision = table.create(asset_count, false),
		assets = table.create(asset_count, ""),
		assets_built = {},
		assets_models = {},
		metadata = {}
	})
end


function plot.build_asset(pos, name, assetName)
	local p = plot.get_by_folder(pos.plot)
	if p == nil then
		return false
	end
	local gridlayer = plot.gridlayer_get(p, name, pos.pos.Y)
	if gridlayer == nil then
		return false
	end

	if pos.pos.X < 0 or pos.pos.Z < 0 or pos.pos.X >= p.size.X or pos.pos.Z >= p.size.Y then
		return false
	end
	local oldasset = plot.gridlayer_get_asset(gridlayer, pos)
	if oldasset == assetName then
		return false
	end
	if oldasset ~= "" then
		plot.collisionmesh_remove(pos, asset.collisionmesh_get(oldasset))
	end
	plot.gridlayer_set_asset(gridlayer, pos, assetName)
	p.dirty = true

	if assetName ~= "" then
		plot.collisionmesh_place(pos, asset.collisionmesh_get(assetName))
	end
	plot.update_push(pos)

	return true
end


function plot.replicate(plot)
	if not plot.dirty then
		return
	end
	plot.dirty = false
	replicatedStorage.Remotes.PlotReplicateEvent:FireAllClients(plot)
	table.clear(plot.updates)
end


replicatedStorage.Remotes.PlotReplicateEvent.OnServerEvent:Connect(function(player: Player)
	for _, p in plot.allPlots do
		if p.owner == player then
			replicatedStorage.Remotes.PlotReplicateEvent:FireClient(player, p)
		end
	end
end)



function plot.save(p)
	local owner = p.owner
	if owner == nil then
		return
	end
	local serialized = data.load_plot(owner)
	table.clear(serialized.layers)
	for _, layer in p.layers do
		local layer_serialized: data.layer_serialized = {
			height = layer.height,
			name = layer.name,
			type = layer.type,
			assets = layer.assets,
			size = {
				x = p.size.X,
				z = p.size.Y
			}
		}
		table.insert(serialized.layers, layer_serialized)
	end
end


local function layer_resize(l: data.layer_serialized, to: Vector2int16): {string}
	local layer = plot.layers[l.type]
	if layer == nil then
		return table.create(to.X * to.Y, "")
	end
	return layer.resize(l.assets, Vector2int16.new(l.size.x, l.size.z), to)
end


function plot.load(p, player)
	local serialized = data.load_plot(player)
	local processed = 0
	local last = tick()
	for _, layer in serialized.layers do
		local gridlayer = plot.gridlayer_get(p, layer.name, layer.height)
		if gridlayer == nil then
			continue
		end
		gridlayer.assets = layer_resize(layer, p.size)
		for i, assetName in gridlayer.assets do
			if assetName == "" then
				continue
			end
			local pos = plot.layers[gridlayer.type].get_position(p, i)
			pos = position.translate(pos, 0, 0, layer.height, 0)
			local mesh = asset.collisionmesh_get(assetName)
			plot.collisionmesh_place(pos, mesh)

			Tycoon.on_build_fire(p, pos, assetName, layer.name)
			processed += 1
			local cur = tick()
			if cur - last > 1/60 then
				print(`Procedded {processed} in {(cur-last) * 1000} ms`)
				task.wait()
				last = tick()
				processed = 0
			end
		end
	end
	p.dirty = true
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
	build = function(p, gridlayer, destination) end,
	build_cell = function(p, gridlayer, destination) end,
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
	build = function(p, gridlayer, destination) end,
	build_cell = function(p, gridlayer, destination) end,
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


local function is_in_bounds(p: plot.plot, pos: Vector3): boolean
	return pos.X >= 0 and pos.Y >= 0 and pos.Z >= 0 and pos.X < p.size.X and pos.Z < p.size.Y
end


local function heuristic_distance(a: Vector3, b: Vector3)
	return (b - a).Magnitude
end


local function getDirectionInfo(p: plot.plot, from: Vector3, dir: Vector3)
	local rot = 0
	if dir == Vector3.xAxis then
		rot = 2
	elseif dir == Vector3.zAxis then
		rot = 1
	elseif dir == -Vector3.xAxis then
		rot = 0
	elseif dir == -Vector3.zAxis then
		rot = 3
	end

	local wall_current = plot.get_asset({
		pos = from,
		rot = rot,
		plot = p.folder
	}, "wall_outer")
	local wall_adjacent = plot.get_asset({
		pos = from + dir,
		rot = (rot + 2) % 4,
		plot = p.folder
	}, "wall_outer")

	local is_wall = wall_current ~= "" or wall_adjacent ~= ""

	local door_current = plot.get_asset({
		pos = from,
		rot = rot,
		plot = p.folder
	}, "wall_inner")
	local door_adjacent = plot.get_asset({
		pos = from + dir,
		rot = (rot + 2) % 4,
		plot = p.folder
	}, "wall_inner")

	local is_door = door_current:find("Door") or door_adjacent:find("Door")
	return {
		is_wall = is_wall,
		is_walkable = is_door and true or false,
		rot = rot
	}
end

local nodegraphs_by_folder = {}

local function nodegraph_construct(p: plot.plot): nodegraph.nodegraph<Vector3>
	local nodes = {}
	local layer_indices = {}
	
	if nodegraphs_by_folder[p.folder] then
		return nodegraphs_by_folder[p.folder]
	end

	for _, layer in p.layers do
		if layer_indices[layer.height] ~= nil then
			continue
		end
		local indices = {}
		layer_indices[layer.height] = indices
		for x = 0, p.size.X - 1 do
			for z = 0, p.size.Y - 1 do
				local idx = plot.layers.center.get_index(p, x, z, 0)
				local node = {
					value = Vector3.new(x, layer.height, z),
					edges = {},
					distance = math.huge
				}
				indices[idx] = node
				table.insert(nodes, node)
			end
		end
	end


	for y, layer in layer_indices do
		for x = 1, p.size.X - 1 do
			for z = 1, p.size.Y - 1 do
				local pos = Vector3.new(x, y, z)
				local info_x = getDirectionInfo(p, pos, -Vector3.xAxis)
				local info_z = getDirectionInfo(p, pos, -Vector3.zAxis)
				local cur = layer[plot.layers.center.get_index(p, x, z, 0)]
				if not info_x.is_wall or info_x.is_walkable then
					nodegraph.node_connect(cur, layer[plot.layers.center.get_index(p, x-1, z, 0)], heuristic_distance)
				end
				if not info_z.is_wall or info_z.is_walkable then
					nodegraph.node_connect(cur, layer[plot.layers.center.get_index(p, x, z-1, 0)], heuristic_distance)
				end
			end
		end
		for x = 1, p.size.X - 1 do
			local cur = layer[plot.layers.center.get_index(p, x, 0, 0)]
			local pos = Vector3.new(x, y, 1)
			local info_x = getDirectionInfo(p, pos, -Vector3.xAxis)
			if not info_x.is_wall or info_x.is_walkable then
				nodegraph.node_connect(cur, layer[plot.layers.center.get_index(p, x-1, 0, 0)], heuristic_distance)
			end
		end
		for z = 1, p.size.Y - 1 do
			local cur = layer[plot.layers.center.get_index(p, 0, z, 0)]
			local pos = Vector3.new(1, y, z)
			local info_z = getDirectionInfo(p, pos, -Vector3.zAxis)
			if not info_z.is_wall or info_z.is_walkable then
				nodegraph.node_connect(cur, layer[plot.layers.center.get_index(p, 0, z-1, 0)], heuristic_distance)
			end
		end
	end


	return {
		nodes = nodes,
		layer_indices = layer_indices
	}
end

type roomInfo = {
	doors: {Vector3},
	cells: {Vector3}
}
local function getRoomInfo(p: plot.plot, pos: Vector3): roomInfo
	local closed = {}
	local open = {pos}
	local cells = {pos}
	local doors = {}
	
	repeat
		local cur = open[#open]
		open[#open] = nil
		local potential_neighbours = {
			Vector3.xAxis,
			Vector3.zAxis,
			-Vector3.xAxis,
			-Vector3.zAxis
		}
		for i, dir in potential_neighbours do
			if not is_in_bounds(p, cur + dir) then
				continue
			end
			if closed[tostring(cur + dir)] then
				continue
			end
			closed[tostring(cur + dir)] = true
			local info = getDirectionInfo(p, cur, dir)
			if info.is_wall then
				if info.is_walkable then
					table.insert(doors, cur + dir * 0.5)
				end
			else
				local pos = cur + dir
				table.insert(cells, pos)
				table.insert(open, cur + dir)
			end
		end
	until not open[1]

	return {
		doors = doors,
		cells = cells
	}
end


local function floodFillRoom(p: plot.plot, pos: Vector3, indices: {nodegraph.node<Vector3>}): {nodegraph.node<Vector3>}
	local closed = {}
	local open = {pos}
	local node_center = {
		value = pos,
		edges = {},
		distance = math.huge
	}
	local nodes_created = {node_center}

	repeat
		local cur = open[#open]
		open[#open] = nil
		local potential_neighbours = {
			Vector3.xAxis,
			Vector3.zAxis,
			-Vector3.xAxis,
			-Vector3.zAxis
		}
		for i, dir in potential_neighbours do
			if not is_in_bounds(p, cur + dir) then
				continue
			end
			if closed[tostring(cur + dir)] then
				continue
			end
			closed[tostring(cur + dir)] = true
			local info = getDirectionInfo(p, cur, dir)
			if info.is_wall then
				if info.is_walkable then
					local node_new = nodegraph.node_create(cur + dir * 0.5)
					nodegraph.node_connect(node_new, node_center, heuristic_distance)
				end
			else
				local pos = cur + dir
				local idx = plot.layers.center.get_index(p, pos.X, pos.Z, info.rot)
				indices[idx] = node_center
				table.insert(open, cur + dir)
			end
		end
	until not open[1]

	return nodes_created
end


function plot.pathfind_update_map(p)
	local nodes: {nodegraph.node<Vector3>} = {}
	local layer_indices: {{nodegraph.node<Vector3>}} = {}
	nodegraphs_by_folder[p.folder] = {
		nodes = nodes,
		layer_indices = layer_indices
	}

	local doorNodes: {[string]: nodegraph.node<Vector3>} = {}

	for _, layer in p.layers do
		if layer_indices[layer.height] ~= nil then
			continue
		end
		local indices: {nodegraph.node<Vector3>} = {}
		layer_indices[layer.height] = indices
		for x = 0, p.size.X - 1 do
			for z = 0, p.size.Y - 1 do
				local pos = Vector3.new(x, layer.height, z)
				local idx = plot.layers.center.get_index(p, x, z, 0)
				if indices[idx] ~= nil then
					continue
				end

				--[[
				for _, node in floodFillRoom(p, pos, indices) do
					table.insert(nodes, node)
				end]]
				
				local roomInfo = getRoomInfo(p, pos)
				local node_center = nodegraph.node_create(pos)
				table.insert(nodes, node_center)
				local doors = {}
				for _, cell in roomInfo.cells do
					local idx = plot.layers.center.get_index(p, cell.X, cell.Z, 0)
					indices[idx] = node_center
				end
				for i, door in roomInfo.doors do
					local key = `{door:Floor()}-{door:Ceil()}`
					if doorNodes[key] == nil then
						doorNodes[key] = nodegraph.node_create(door)
					end
					
					doors[i] = doorNodes[key]
					nodegraph.node_connect(doors[i], node_center, heuristic_distance)
					table.insert(nodes, doors[i])
					for i2 = 1, i-1 do
						nodegraph.node_connect(doors[i], doors[i2], heuristic_distance)
					end
				end
			end
		end
	end
end


local visualNodes: {Instance} = {}


function plot.pathfind_to(from, to)
	local p = plot.get_by_folder(from.plot)
	if p == nil then
		return {}
	end
	if not is_in_bounds(p, to.pos) then
		return {from}
	end
	
	plot.pathfind_update_map(p)
	local graph = nodegraph_construct(p)
	local layer_from = graph.layer_indices[from.pos.Y]
	local layer_to = graph.layer_indices[to.pos.Y]
	local idx_from = plot.layers.center.get_index(p, from.pos.X, from.pos.Z, 0)
	local idx_to = plot.layers.center.get_index(p, to.pos.X, to.pos.Z, 0)

	local nodes = nodegraph.pathfind_astar(
		graph,
		layer_from[idx_from],
		layer_to[idx_to],
		function(a: Vector3, b: Vector3)
			return math.abs(a.X - b.X) + math.abs(a.Y - b.Y) + math.abs(a.Z - b.Z)
		end
	)
	
	nodes[1] = from.pos
	nodes[#nodes] = to.pos
	if #nodes == 1 then
		nodes = {
			from.pos,
			to.pos
		}
	end
	
	local path = {}
	for i = 1, #nodes do
		path[i] = {
			pos = nodes[i],
			rot = 0,
			plot = from.plot
		}
	end
	return path
end



return true