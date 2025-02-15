--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local selection = game:GetService("Selection")
local otf = replicatedStorage.OTF
local contracts = otf.Client.Contracts
local common = otf.Common
local Elements = require(contracts.UI.Elements)
local Config = require(common.Config)

local frame = Elements.create_frame()
local frame_content


local layer_current = ""
local layers = {}
local grid_size = 7
for layer_name, layer_type in Config.plot.layers do
	if layer_type == "center" then
		layers[layer_name] = table.create(grid_size * grid_size)
	elseif layer_type == "edge" then
		layers[layer_name] = table.create(grid_size * grid_size * 4)
	end
end
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


local function createCenterGrid(parent, size: number): Frame
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
			frame.BackgroundTransparency = 0

			i += 1
			local index = i
			print(layer_selected, index, layer_selected[index], colors)
			frame.BackgroundColor3 = colors[layer_selected[index]]

			Elements.on_press(frame, function(x, y)
				layer_selected[index] = (layer_selected[index] + 1) % 3
				frame.BackgroundColor3 = colors[layer_selected[index]]
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


local function saveCenterLayer(item, name, size)
	local layer_selected = layers[name]
	local i = 0
	for x = -size, size do
		for z = -size, size do
			i += 1
			if layer_selected[i] == 0 then
				continue
			end
			local bool = Instance.new("BoolValue")
			bool.Value = layer_selected[i] == 1
			bool:SetAttribute("x", x)
			bool:SetAttribute("z", z)
			bool:SetAttribute("rot", 0)
			bool:SetAttribute("layer", name)
			bool.Parent = item
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

	for layer_name, layer_type in Config.plot.layers do
		if layer_type == "edge" then
			saveEdgeLayer(item_selected, layer_name, (grid_size - 1) / 2)
		elseif layer_type == "center" then
			saveCenterLayer(item_selected, layer_name, (grid_size - 1) / 2)
		end
	end
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
		local layer_type = Config.plot.layers[layer_name]
		local i = 0
		if layer_type == "edge" then
			i = rot + 4 * ((z+3) + (x+3) * 7) + 1
		elseif layer_type == "center" then
			i = ((z+3) + (x+3) * 7) + 1
		else
			error("Unexpected layer type")
		end
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

	local frame_allcontent = Elements.create_list(frame_content, UDim.new(0, 0), Enum.FillDirection.Horizontal)
	local layerList_frame = Elements.create_frame(frame_allcontent, UDim2.new(0, 100, 1, 0))
	Elements.style_flex(layerList_frame, 0, 0)
	
	local content = Elements.create_frame(frame_allcontent, UDim2.new(1, 0, 1, 0), UDim2.new(0, 100, 0, 0))
	Elements.style_flex(content, 1, 0)

	local list_layers = Elements.create_list(Elements.create_background(layerList_frame, "bg_primary", "bg_dark"), UDim.new(0, 5), Enum.FillDirection.Vertical)
	
	for layer_name in Config.plot.layers do
		local btn = Elements.create_pill(list_layers, layer_name, "x")
		Elements.on_click(btn, function()
			Elements.clear(content)
			layer_current = layer_name
			if Config.plot.layers[layer_name] == "edge" then
				createEdgeGrid(content, (grid_size - 1) / 2)
			else
				createCenterGrid(content, (grid_size - 1) / 2)
			end
		end)
	end
	Elements.style_pop()
end


local function on_active(widget)
	frame.Parent = widget
	Elements.clear(frame)
	local root = Elements.create_list(frame, UDim.new(0, 0), Enum.FillDirection.Vertical)
	local topbar = Elements.create_background(
		Elements.create_frame(root, UDim2.new(1, 0, 0, 30)),
		"bg_header", "bg_dark"
	)
	frame_content = Elements.create_frame(root)
	Elements.style_flex(frame_content, 1, 0)

	local topbar_list = Elements.create_list(topbar, UDim.new(0, 5), Enum.FillDirection.Horizontal)
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