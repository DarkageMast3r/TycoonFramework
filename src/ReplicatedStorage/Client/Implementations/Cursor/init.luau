--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local players = game:GetService("Players")

local contracts = script.Parent.Parent.Contracts
local common = replicatedStorage.Common
local ActionManager = require(contracts.ActionManager)
local Cursor = require(contracts.Cursor)
local Asset = require(common.Asset.Asset)
local Config = require(common.Config)

Cursor.current = {
	pos = {
		pos = Vector3.new(),
		rot = 0,
		plot = nil
	},
	asset = "",
	type = "",
	dragmode = "square"
}
local cursor_pos = Vector3.new()

function Cursor.asset_select(name)
	Cursor.current.type = Asset.resolve_type(name)
	Cursor.current.asset = name
end


local function calculate_rotation(vec: Vector3)
	local rot = math.atan2(vec.X, vec.Z)
	return (math.floor(rot / math.pi * 2 + 2.5) - 1) % 4
end


local function get_plot(p: Instance): Folder?
	repeat
		p = p.Parent :: Instance
	until p.Parent == nil or p:HasTag("Grid") and p:IsA("Folder")
	if p:HasTag("Grid") then
		if p:IsA("Folder") then
			return p
		end
	end
	return nil
end


local function get_asset_model(p: Instance): Model?
	repeat
		p = p.Parent :: Instance
	until p.Parent == nil or p:IsA("Model")
	if p:IsA("Model") then
		return p
	end
	return nil
end


function Cursor.update_location(select_hit_instance: boolean)
	local loc = userInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(loc.X, loc.Y)
	local filter = {}
	local localPlayer = players.LocalPlayer
	if localPlayer and localPlayer.Character and localPlayer.Character.Parent then
		table.insert(filter, localPlayer.Character)
	end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = filter
	
	local results = workspace:Raycast(ray.Origin, ray.Direction * 512, params)
	if not results then
		Cursor.current.pos.plot = nil
		return
	end
	Cursor.current.hit_instance = results.Instance
	local plot_folder = get_plot(results.Instance)
	Cursor.current.pos.plot = plot_folder
	
	if not plot_folder then
		return
	end
	
	if select_hit_instance then
		local model = get_asset_model(results.Instance)
		if model == nil then
			return
		end

		local gridPart = plot_folder:FindFirstChild("Grid")
		if not gridPart:IsA("Part") then
			return
		end
		
		local pivot = model:GetPivot()

		local rel = gridPart.CFrame:PointToObjectSpace(pivot.Position)
			+ gridPart.Size * Vector3.new(0.5, 0, 0.5)

		rel /= Config.cell.size
		Cursor.current.pos.rot = calculate_rotation(pivot.LookVector)
		Cursor.current.pos.pos = Vector3.new(
			math.floor(rel.X),
			math.floor(rel.Y),
			math.floor(rel.Z)
		)
	else
		local gridPart = plot_folder:FindFirstChild("Grid")
		if not gridPart:IsA("Part") then
			return
		end

		local cursorPos = results.Position + results.Normal
		local rel = gridPart.CFrame:PointToObjectSpace(cursorPos)
			+ gridPart.Size * Vector3.new(0.5, 0, 0.5)

		rel /= Config.cell.size
		cursor_pos = rel
		Cursor.current.pos.pos = Vector3.new(
			math.floor(rel.X),
			math.floor(rel.Y),
			math.floor(rel.Z)
		)
	end
end


function Cursor.set_state_build()
	Cursor.tool_select("Build")
end


function Cursor.set_state_delete()
	Cursor.tool_select("Delete")
end


function Cursor.set_state_dragmode(mode)
	Cursor.current.dragmode = mode
end


local tools = {}
local tool_current = ""


function Cursor.update()
	if tools[tool_current] then
		tools[tool_current].update()
	end
end


function Cursor.tool_select(tool)
	if tools[tool_current] then
		tools[tool_current].unload()
	end
	tool_current = tool
	if tools[tool_current] then
		tools[tool_current].load()
	end
end


function Cursor.tool_action_begin()
	if tools[tool_current] then
		tools[tool_current].begin()
	end
end


function Cursor.tool_action_end()
	if tools[tool_current] then
		tools[tool_current].finish()
	end
end


function Cursor.tool_register(tool, load, unload, action_begin, action_end, update)
	tools[tool] = {
		load = load,
		unload = unload,
		begin = action_begin,
		finish = action_end,
		update = update
	}
end


ActionManager.register("action", "press", function(pressed)
	if pressed then
		Cursor.tool_action_begin()
	else
		Cursor.tool_action_end()
	end
end)
ActionManager.register("rotate", "press", function(pressed: boolean)
	if pressed then
		Cursor.current.pos.rot = (Cursor.current.pos.rot + 1) % 4
	end
end)



return true