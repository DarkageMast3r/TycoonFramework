--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local selection = game:GetService("Selection")
local contracts = replicatedStorage.OTF.Client.Contracts
local Elements = require(contracts.UI.Elements)

local frame = Elements.create_frame()
local frame_content


local layer_current = ""
local layers = {
	wall_outer = table.create(49 * 4, 0),
	wall_inner = table.create(49 * 4, 0),
	asset = table.create(49 * 4, 0),
	light = table.create(49 * 4, 0)
}
local colors = {
	[0] = Color3.new(0.7, 0.7, 0.7),
	Color3.new(0.3, 0.8, 0.3),
	Color3.new(0.8, 0.3, 0.3)
}


local function createEdgeGrid(parent, size: number): Frame
	local padding = 2
	local imgsize = 32
	local parentFrame = Elements.create_frame(
		parent,
		UDim2.fromOffset(
			(padding + imgsize) * (size * 2 + 1) - padding,
			(padding + imgsize) * (size * 2 + 1) - padding
		),
		UDim2.fromOffset(0, 0)
	)
	local i = 0
	local layer_selected = layers[layer_current]
	for x = -size, size do
		for z = -size, size do
			local frame = Elements.create_frame(
				parentFrame,
				UDim2.fromOffset(imgsize, imgsize),
				UDim2.fromOffset((x+size) * (imgsize + padding), (z+size) * (imgsize + padding))
			)
			local indices = {}
			local images = {}
			
			for rot = 0, 3 do
				i += 1
				local img = Elements.create_image(frame, 96753806776558)
				img.Rotation = rot * -90
				img.ImageColor3 = colors[layer_selected[i]]
				indices[rot] = i
				images[rot] = img
			end
			
			Elements.on_press(frame, function(x, y)
				x -= frame.AbsolutePosition.X
				y -= frame.AbsolutePosition.Y
				local rot = 0
				if x > y then
					if x + y > imgsize then
						rot = 3
					else
						rot = 0
					end
				else
					if x + y > imgsize then
						rot = 2
					else
						rot = 1
					end
				end
				local index = indices[rot]
				local img = images[rot]
				layer_selected[index] = (layer_selected[index] + 1) % 3
				img.ImageColor3 = colors[layer_selected[index]]
			end)
		end
	end
	return parentFrame
end


local item_selected: Instance? = nil


local function saveEdgeLayer(item, name, size)
	local layer_selected = layers[name]
	local i = 0
	for x = -size, size do
		for z = -size, size do
			for rot = 0, 3 do
				i += 1
				if layer_selected[i] == 0 then
					continue
				end
				local bool = Instance.new("BoolValue")
				bool.Value = layer_selected[i] == 1
				bool:SetAttribute("x", x)
				bool:SetAttribute("z", z)
				bool:SetAttribute("rot", rot)
				bool:SetAttribute("layer", name)
				bool.Parent = item
			end
		end
	end
end


local function saveItem()
	if item_selected == nil then
		return
	end
	
	for _, child in item_selected:GetChildren() do
		if child:IsA("BoolValue") then
			child:Destroy()
		end
	end

	saveEdgeLayer(item_selected, "wall_inner", 3)
	saveEdgeLayer(item_selected, "wall_outer", 3)
	saveEdgeLayer(item_selected, "asset", 3)
	saveEdgeLayer(item_selected, "light", 3)
end


local function loadItem()
	if item_selected == nil then
		return
	end
	for _, layer in layers :: {[string]: {number}} do
		for i, item in layer do
			layer[i] = 0
		end
	end
	for _, boolValue in item_selected:GetChildren() do
		if not boolValue:IsA("BoolValue") then
			continue
		end

		local x = boolValue:GetAttribute("x") :: number
		local z = boolValue:GetAttribute("z") :: number
		local rot = boolValue:GetAttribute("rot") :: number
		local layer_name = boolValue:GetAttribute("layer") :: string
		local i = rot + 4 * ((z+3) + (x+3) * 7) + 1
		layers[layer_name][i] = boolValue.Value and 1 or 2
	end
end


local function selectItem()
	local selected = selection:Get()[1]
	while selected.Parent ~= nil and not selected:IsA("Model") do
		selected = selected.Parent
	end
	item_selected = selected
	loadItem()
	
	
	Elements.clear(frame_content)

	local layerList_frame = Elements.create_frame(frame_content, UDim2.new(0, 100, 1, 0), UDim2.new(0, 0, 0, 0))
	local content = Elements.create_frame(frame_content, UDim2.new(1, -100, 1, 0), UDim2.new(0, 100, 0, 0))
	local list_layers = Elements.create_list(layerList_frame, UDim.new(0, 5), Enum.FillDirection.Vertical)
	local layers: {[string]: string} = {
		Wall = "wall_outer",
		Decoration = "wall_inner",
		Asset = "asset",
		Light = "light"
	}
	
	for name, code in layers do
		local btn = Elements.create_pill(list_layers, name, "x")
		Elements.on_click(btn, function()
			Elements.clear(content)
			layer_current = code
			createEdgeGrid(content, 3)
		end)
	end
	Elements.style_pop()
end


local function on_active(widget)
	frame.Parent = widget
	Elements.clear(frame)
	local topbar = Elements.create_frame(frame, UDim2.new(1, 0, 0, 25), UDim2.new(0, 0, 0, 0))
	frame_content = Elements.create_frame(frame, UDim2.new(1, 0, 1, -25), UDim2.new(0, 0, 0, 25))
	local topbar_list = Elements.create_list(topbar, UDim.new(0, 5))

	local btn_select = Elements.create_pill(topbar_list, "Select")
	local btn_save = Elements.create_pill(topbar_list, "Save")
	Elements.on_click(btn_select, selectItem)
	Elements.on_click(btn_save, saveItem)
	
	Elements.style_pop()
end


return {
	type = "widget",
	description = "Edit the placement collisions of items",
	icon = 8740888472,
	on_active = on_active
}