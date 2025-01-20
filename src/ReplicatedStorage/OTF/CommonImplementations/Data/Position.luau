--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common

local Position = require(common.Data.Position)
local Plot = require(common.Plot)
local Config = require(common.Config)

function Position.is_valid(pos)
	if typeof(pos) ~= "table" then
		return false
	end
	if pos.pos == nil or pos.rot == nil then
		return false
	end
	if typeof(pos.pos) ~= "Vector3" or typeof(pos.rot) ~= "number" then
		return false
	end
	if pos.plot ~= nil then
		if typeof(pos.plot) ~= "Instance" then
			return false
		end
		if not pos.plot:IsA("Folder") then
			return false
		end
	end
	return true
end

local translations = {
	Vector3.new( 0, 0,  1),
	Vector3.new( 1, 0,  0),
	Vector3.new( 0, 0, -1),
	Vector3.new(-1, 0,  0)
}
function Position.translate(pos, forward, right, up, rot)
	return {
		pos = pos.pos
			+ translations[(pos.rot - 1) % 4 + 1] * forward
			+ translations[(pos.rot % 4) + 1] * right
			+ Vector3.new(0, up, 0),
		rot = (pos.rot + rot) % 4,
		plot = pos.plot
	}
end


function Position.distance(a, b)
	if a.plot ~= b.plot then
		return math.huge
	end
	
	return (a.pos - b.pos).Magnitude
end


function Position.object_to_world(a)
	local p = Plot.get_by_folder(a.plot)
	if p == nil then
		return Vector3.new(
			(a.pos.X + 0.5),
			a.pos.Y,
			(a.pos.Z + 0.5)
		) * Config.cell.size
	else
		return p.origin:PointToWorldSpace(Vector3.new(
			(a.pos.X - p.size.X / 2 + 0.5),
			a.pos.Y,
			(a.pos.Z - p.size.Y / 2 + 0.5)
		) * Config.cell.size)
	end
end


function Position.object_to_world_cf(a)
	local p = Plot.get_by_folder(a.plot)
	if p == nil then
		return CFrame.new(
			Vector3.new(
				(a.pos.X + 0.5),
				a.pos.Y,
				(a.pos.Z + 0.5)
			) * Config.cell.size
		) * CFrame.Angles(0, a.rot * math.pi * 0.5, 0)
	else
		return p.origin:ToWorldSpace(
			CFrame.new(
				Vector3.new(
					(a.pos.X - p.size.X / 2 + 0.5),
					a.pos.Y,
					(a.pos.Z - p.size.Y / 2 + 0.5)
				) * Config.cell.size
			)
		) * CFrame.Angles(0, a.rot * math.pi * 0.5, 0)
	end
end


function Position.world_to_object(pos, folder)
	local p = Plot.get_by_folder(folder)
	if p == nil then
		local l = pos / Config.cell.size
		return {
			pos = Vector3.new(
				l.X - 0.5,
				l.Y,
				l.Z - 0.5
			),
			rot = 0
		}
	else
		local l = p.origin:PointToObjectSpace(pos)/ Config.cell.size
		return {
			pos = Vector3.new(
				l.X + p.size.X / 2 - 0.5,
				l.Y,
				l.Z + p.size.Y / 2 - 0.5
			),
			rot = 0,
			plot = p.folder
		}
	end
end


function Position.world_to_object_cf(cf, folder)
	local p = Plot.get_by_folder(folder)
	if p == nil then
		local l = cf.Position / Config.cell.size
		local lp = l
		local lv = cf.LookVector
		return {
			pos = Vector3.new(
				lp.X - 0.5,
				lp.Y,
				lp.Z - 0.5
			),
			rot = math.atan2(lv.Z, lv.X) / math.pi / 0.5,
			plot = nil
		}
	else
		local l = p.origin:ToObjectSpace(cf)
		local lp = l.Position / Config.cell.size
		local lv = l.LookVector
		return {
			pos = Vector3.new(
				lp.X + p.size.X / 2 - 0.5,
				lp.Y,
				lp.Z + p.size.Y / 2 - 0.5
			),
			rot = math.atan2(lv.Z, lv.X) / math.pi / 0.5,
			plot = p.folder
		}
	end
end


return true