local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common

local cursor = require(contracts.Cursor)
local asset = require(common.Asset.Asset)
local position = require(common.Data.Position)
local dragModes = require(common.DragModes)
local config = require(common.Config)

local asset_selected = ""
local highlight: Model = asset.create_by_name("")
local highlight_parts: {Model} = {}

local function highlight_select(name: string)
	highlight:Destroy()
	highlight = asset.create_by_name(name)
	asset.set_uninteractable(highlight)
	highlight.Parent = workspace
end


local function create_text_asset(text: string, width: number, color: Color3): Model
	local model = Instance.new("Model")

	local base = Instance.new("Part", model)
	model.PrimaryPart = base
	base.Anchored = true
	base.CanCollide = false
	base.CanQuery = false
	base.CanTouch = false
	base.Transparency = 1
	base.Size = Vector3.new(1, 1, 1)
	base.CFrame = CFrame.identity
	
	local p = Instance.new("Part", model)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, width) * config.cell.size
	p.CFrame = CFrame.identity + Vector3.new(0, 0.5, 0) * config.cell.size
	
	local surfaceGui = Instance.new("SurfaceGui", p)
	surfaceGui.Face = Enum.NormalId.Right
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	
	local label = Instance.new("TextLabel", surfaceGui)
	label.BackgroundTransparency = 1
	label.TextSize = 50
	label.TextColor3 = color
	label.Text = text
	label.Size = UDim2.fromScale(1, 1)
	
	return model
end


local build_start = Vector3.zero
local isDragging = false
local direction_markers: {[string]: Model} = {}


local function buildPreview(assetName: string, from: Vector3, to: position.position)
	local assetType = asset.resolve_type(assetName)
	local highlight_asset = `Highlight.{assetName:split(".")[1]}`
	local i = 0
	for _, position in dragModes.get_positions(assetType, from, to, cursor.current.dragmode) do
		i += 1
		if highlight_parts[i] == nil then
			highlight_parts[i] = asset.create_by_name(highlight_asset)
			asset.set_uninteractable(highlight_parts[i])
			highlight_parts[i].Parent = workspace
		end
		asset.move_to(highlight_parts[i], position)
	end
	for i = i + 1, #highlight_parts do
		highlight_parts[i]:Destroy()
		highlight_parts[i] = nil
	end

	if direction_markers.x ~= nil then
		direction_markers.x:Destroy()
	end
	if direction_markers.y ~= nil then
		direction_markers.y:Destroy()
	end
	if direction_markers.x2 ~= nil then
		direction_markers.x2:Destroy()
	end
	if direction_markers.y2 ~= nil then
		direction_markers.y2:Destroy()
	end

	local min = from:Min(to.pos)
	local max = from:Max(to.pos)
	
	local width = max.X - min.X + 1
	local height = max.Z - min.Z + 1
	direction_markers.x = create_text_asset(tostring(width), width, Color3.fromRGB(252, 255, 87))
	direction_markers.y = create_text_asset(tostring(height), height, Color3.fromRGB(252, 255, 87))
	direction_markers.x2 = create_text_asset(tostring(width), width, Color3.fromRGB(252, 255, 87))
	direction_markers.y2 = create_text_asset(tostring(height), height, Color3.fromRGB(252, 255, 87))
	direction_markers.x.Parent = workspace
	direction_markers.y.Parent = workspace
	direction_markers.x2.Parent = workspace
	direction_markers.y2.Parent = workspace
	asset.move_to(direction_markers.x, {
		pos = Vector3.new((min.X + max.X) / 2, min.Y, min.Z - 1),
		rot = 3,
		plot = to.plot
	})
	asset.move_to(direction_markers.y, {
		pos = Vector3.new(min.X - 1, min.Y, (min.Z + max.Z) / 2),
		rot = 0,
		plot = to.plot
	})
	asset.move_to(direction_markers.x2, {
		pos = Vector3.new((min.X + max.X) / 2, min.Y, max.Z + 1),
		rot = 1,
		plot = to.plot
	})
	asset.move_to(direction_markers.y2, {
		pos = Vector3.new(max.X + 1, min.Y, (min.Z + max.Z) / 2),
		rot = 2,
		plot = to.plot
	})
end


local function sendBuildCommand()
	if isDragging then
		replicatedStorage.Remotes.PlotBuildEvent:FireServer(
			build_start,
			cursor.current.pos,
			cursor.current.asset,
			cursor.current.dragmode
		)
	else
		replicatedStorage.Remotes.PlotBuildEvent:FireServer(
			cursor.current.pos.pos,
			cursor.current.pos,
			cursor.current.asset,
			"single"
		)
	end
end


local function isDraggable(assetName: string)
	local assetType = asset.resolve_type(assetName)
	return assetType == "floor" or assetType == "wall_outer" or assetType == "ceiling"
end


cursor.tool_register(
	"Build",
	function()
		highlight_select(asset_selected)
	end,
	function()
		highlight_select("")
	end,
	function()
		if isDraggable(asset_selected) then
			isDragging = true
			build_start = cursor.current.pos.pos
			highlight_select("")
		else
			sendBuildCommand()
		end
	end,
	function()
		if isDragging then
			sendBuildCommand()
			isDragging = false
			for _, model in highlight_parts do
				model:Destroy()
			end
			for _, model in direction_markers do
				model:Destroy()
			end
			highlight_parts = {}
			highlight_select(asset_selected)
		end
	end,
	function()
		cursor.update_location(false)
		if cursor.current.asset ~= asset_selected then
			asset_selected = cursor.current.asset
			highlight_select(asset_selected)
		end
		asset.move_to(highlight, position.translate(cursor.current.pos, 0, 0, 0.001, 0))
		if isDragging then
			buildPreview(asset_selected, build_start, cursor.current.pos)
		end
	end
)

return true