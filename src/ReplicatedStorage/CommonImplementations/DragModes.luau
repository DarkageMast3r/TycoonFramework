--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local common = replicatedStorage.Common
local position = require(common.Data.Position)
local dragModes = require(common.DragModes)


local function get_positions_floor_square(from: Vector3, to: position.position): {position.position}
	local from_pos = from:Min(to.pos)
	local to_pos = from:Max(to.pos)

	local result = {}
	for x = from_pos.X, to_pos.X do
		for z = from_pos.Z, to_pos.Z do
			table.insert(result, {
				pos = Vector3.new(x, from.Y, z),
				rot = 0,
				plot = to.plot
			})
		end
	end
	return result
end


local function get_positions_floor_line(from: Vector3, to: position.position): {position.position}
	local from_pos = from:Min(to.pos)
	local to_pos = from:Max(to.pos)

	local is_other_side = to.rot % 2 == 0

	local result = {}
	for x = from_pos.X, to_pos.X do
		table.insert(result, {
			pos = Vector3.new(x, from.Y, is_other_side and to_pos.Z or from_pos.Z),
			rot = 0,
			plot = to.plot
		})
	end
	for z = from_pos.Z, to_pos.Z do
		table.insert(result, {
			pos = Vector3.new(is_other_side and from_pos.X or to_pos.X, from.Y, z),
			rot = 0,
			plot = to.plot
		})
	end
	return result
end


local function get_positions_wall_line(from_raw: Vector3, to_raw: position.position): {position.position}
	local from = from_raw:Min(to_raw.pos)
	local to = from_raw:Max(to_raw.pos)

	local isOtherSide = to_raw.rot % 2 == 0
	local aIsOtherSide = isOtherSide
	local bIsOtherSide = isOtherSide
	local rot_a = to_raw.rot
	local rot_b = to_raw.rot
	if from_raw.X > to_raw.pos.X then
		bIsOtherSide = not bIsOtherSide
		rot_b = (rot_b + 2) % 4
	end
	if from_raw.Z > to_raw.pos.Z then
		aIsOtherSide = not aIsOtherSide
		rot_a = (rot_a + 2) % 4
	end
	local is_inner = to_raw.rot == 2 or to_raw.rot == 3
	local len_x = to.X - from.X
	local len_z = to.Z - from.Z
	local from_x = from.X
	local from_z = from.Z
	if is_inner then
		len_x -= 1
		len_z -= 1
		if to_raw.rot == 2 then
			if not (from_raw.X > to_raw.pos.X) then
				from_x += 1
			end
			if from_raw.Z > to_raw.pos.Z then
				from_z += 1
			end
		else
			if from_raw.X > to_raw.pos.X then
				from_x += 1
			end
			if not (from_raw.Z > to_raw.pos.Z) then
				from_z += 1
			end
		end
	end

	local rotations = {
		{1, 3, 3, 1},
		{0, 2, 2, 0}
	}
	local result = {}
	for x = from_x, from_x + len_x do
		table.insert(result, {
			pos = Vector3.new(x, from.Y, aIsOtherSide and to.Z or from.Z),
			rot = rotations[1][rot_a % 4 + 1],
			plot = to_raw.plot
		})
	end
	for z = from_z, from_z + len_z do
		table.insert(result, {
			pos = Vector3.new(bIsOtherSide and from.X or to.X, from.Y, z),
			rot = rotations[2][rot_b % 4 + 1],
			plot = to_raw.plot
		})
	end
	return result
end


local function get_positions_wall_square(from_raw: Vector3, to_raw: position.position): {position.position}
	local from = from_raw:Min(to_raw.pos)
	local to = from_raw:Max(to_raw.pos)

	local isOtherSide = to_raw.rot % 2 == 0
	local rot_offset = isOtherSide and 2 or 0
	local pos_offet = isOtherSide and 1 or 0

	local result = {}
	for x = from.X, to.X do
		table.insert(result, {
			pos = Vector3.new(x, from.Y, from.Z - pos_offet),
			rot = (3 + rot_offset) % 4,
			plot = to_raw.plot
		})
		table.insert(result, {
			pos = Vector3.new(x, from.Y, to.Z + pos_offet),
			rot = (1 + rot_offset) % 4,
			plot = to_raw.plot
		})
	end
	for z = from.Z, to.Z do
		table.insert(result, {
			pos = Vector3.new(from.X - pos_offet, from.Y, z),
			rot = (0 + rot_offset) % 4,
			plot = to_raw.plot
		})
		table.insert(result, {
			pos = Vector3.new(to.X + pos_offet, from.Y, z),
			rot = (2 + rot_offset) % 4,
			plot = to_raw.plot
		})
	end
	return result
end


local function get_positions_single(from_raw: Vector3, to_raw: position.position): {position.position}
	return {{pos = from_raw, rot = to_raw.rot, plot = to_raw.plot}}
end


local dragmodes = {
	floor = {
		square = get_positions_floor_square,
		line = get_positions_floor_line,
		single = get_positions_single
	},
	wall_outer = {
		square = get_positions_wall_square,
		line = get_positions_wall_line,
		single = get_positions_single
	}
}


function dragModes.get_positions(mode, from, to, dragmode)
	if not dragmodes[mode] then
		return get_positions_single(from, to)
	end
	if not dragmodes[mode][dragmode] then
		return dragmodes[mode].square(from, to)
	end
	return dragmodes[mode][dragmode](from, to)
end


return true