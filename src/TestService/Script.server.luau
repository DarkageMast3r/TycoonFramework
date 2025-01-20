--!strict
local testService = game:GetService("TestService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local server = serverScriptService.Script.Implementations
local common = replicatedStorage.OTF.Common

local Position = require(common.Data.Position)
local Plot = require(common.Plot)
local Asset = require(common.Asset.Asset)
local DragModes = require(common.DragModes)
local Actor = require(common.Actor.Actor)
require(serverScriptService.OTF.Bootloader)()


local p = Plot.create_from_folder(workspace.Grid1)
Plot.gridlayer_attach(p, "center", "floor", 0)
Plot.gridlayer_attach(p, "edge", "wall_outer", 0)

local function convertFromWorldToObjectToToWorld(cur: Vector3)
	local pos_object = Position.world_to_object(cur)
	local pos_world = Position.object_to_world(pos_object)
	testService:Check((pos_world - cur):Abs().Magnitude < 0.01,
		`Expected world_to_object -> object_to_world to return identical values, got {cur} -> {pos_world}`
	)
end
local function convertFromWorldToObjectToToWorldWithPlot(cur: Vector3)
	local pos_object = Position.world_to_object(cur, workspace.Grid1)
	local pos_world = Position.object_to_world(pos_object)
	testService:Check((pos_world - cur):Abs().Magnitude < 0.01,
		`Expected world_to_object -> object_to_world to return identical values, got {cur} -> {pos_world}`
	)
end
local function convertFromWorldToObjectToToWorldWithCF(cf: CFrame)
	local pos_object = Position.world_to_object_cf(cf)
	local pos_world = Position.object_to_world_cf(pos_object)
	testService:Check((pos_world.Position - cf.Position):Abs().Magnitude < 0.01
		and (pos_world.LookVector - cf.LookVector):Abs().Magnitude < 0.01
		and (pos_world.RightVector - cf.RightVector):Abs().Magnitude < 0.01
		and (pos_world.UpVector - cf.UpVector):Abs().Magnitude < 0.01,
		`Expected world_to_object_cf -> object_to_world_cf to return identical values, got {cf} -> {pos_world}`
	)
end


convertFromWorldToObjectToToWorld(Vector3.new(1, 2, 3))
convertFromWorldToObjectToToWorldWithPlot(Vector3.new(1, 2, 3))

--[[
convertFromWorldToObjectToToWorldWithCF(CFrame.new(1, 2, 3) * CFrame.Angles(0, 0, 0))
convertFromWorldToObjectToToWorldWithCF(CFrame.new(1, 2, 3) * CFrame.Angles(0, math.pi * 0.5, 0))
convertFromWorldToObjectToToWorldWithCF(CFrame.new(1, 2, 3) * CFrame.Angles(0, math.pi * 1.0, 0))
convertFromWorldToObjectToToWorldWithCF(CFrame.new(1, 2, 3) * CFrame.Angles(0, math.pi * 1.5, 0))
]]

local function fillWall(assetName, f, t)
	local layer = Asset.resolve_type(assetName)
	local from = f
	local to = {
		pos = t,
		rot = 0,
		plot = p.folder
	}
	local succesCount = 0
	local total = 0
	for _, position in DragModes.get_positions("wall_outer", from, to, "square") do
		total += 1
		succesCount += Plot.build_asset(position, layer, assetName) and 1 or 0
	end
	print(succesCount, total)
end

local function canFloodFillRoom()
	fillWall("Wall_Outer.Brick", Vector3.new(0, 0, 0), Vector3.new(3, 0, 3))
	Plot.build(p)
	print(p)
	local a = Actor.create({
		pos = Vector3.zero,
		rot = 0,
		plot = p.folder
	}, "Npc")
	Actor.walk_to(a, {
		pos = Vector3.new(2, 0, 2),
		rot = 0,
		plot = p.folder
	})
end

canFloodFillRoom()


testService:Done()