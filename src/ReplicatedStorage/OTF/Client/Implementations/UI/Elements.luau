--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local textService = game:GetService("TextService")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Elements = require(contracts.UI.Elements)
local Asset = require(common.Asset.Asset)


local stack_colors = {}
local colors = {
	txt_primary = Color3.new(0, 0, 0),
	bg_primary = Color3.new(1, 1, 1),
	bg_selected = Color3.new(0.6, 0.8, 0.8),
	bg_header = Color3.new(0, 0, 0),
	bg_dark = Color3.new(0, 0, 0),
	bg_unselected = Color3.new(0.3, 0.4, 0.4),
	txt_selected = Color3.new(0, 0, 0)
}

local stack_udims = {}
local udims = {
	padding = UDim.new(0, 5)
}
local stack_numbers = {}
local numbers = {
	font_size = 0
}

local stack_fonts = {}
local fonts = {
	font_primary = Enum.Font.Arimo
}


local function text_get_size(text: string, bounds: Vector2?, font: Enum.Font?, textSize: number?): Vector2
	local size = textService:GetTextSize(
		text,
		textSize or numbers.font_size,
		font or fonts.font_primary,
		bounds or Vector2.new(math.huge, math.huge)
	)
	return size
end


function Elements.style_push()
	table.insert(stack_colors, table.clone(colors))
	table.insert(stack_udims, table.clone(udims))
	table.insert(stack_numbers, table.clone(numbers))
	table.insert(stack_fonts, table.clone(fonts))
end


function Elements.style_pop()
	colors = table.remove(stack_colors) or colors
	udims = table.remove(stack_udims) or udims
	numbers = table.remove(stack_numbers) or numbers
	fonts = table.remove(stack_fonts) or fonts
end


function Elements.style_set_color(option, color)
	colors[option] = color
end


function Elements.style_set_udim(option, udim)
	udims[option] = udim
end


function Elements.style_set_number(option, num)
	numbers[option] = num
end


function Elements.style_set_font(option, font)
	fonts[option] = font
end


function Elements.viewport.create_asset(name)
	local displayAsset = Asset.create_by_name(name)
	local viewport = Instance.new("ViewportFrame")
	displayAsset:PivotTo(CFrame.new(0, 0, 0))
	displayAsset.Parent = viewport
	local camera = Instance.new("Camera")
	local cf, size = displayAsset:GetBoundingBox()
	local dis = size.Magnitude / 2
	local cam_fov = math.rad(camera.FieldOfView)
	local cam_dis = math.cos(cam_fov) / math.tan(cam_fov) * dis + dis + math.sin(cam_fov)
	camera.CFrame = CFrame.lookAt(
		Vector3.new(1, 1, 1).Unit * cam_dis * 1.2,
		Vector3.zero
	) + cf.Position
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	viewport.BackgroundTransparency = 1
	return viewport
end


function Elements.create_texture(parent)
	local tex = Instance.new("CanvasGroup", parent)
	tex.Size = UDim2.fromScale(1, 1)
	tex.BackgroundTransparency = 1
	return tex
end


function Elements.create_frame(parent, size, pos)
	local frame = Instance.new("Frame", parent)
	frame.Size = size or UDim2.fromScale(1, 1)
	frame.Position = pos or UDim2.fromOffset(0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	return frame
end


function Elements.create_background(parent, color_background, color_border)
	local frame = Instance.new("Frame", parent)
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromOffset(0, 0)
	frame.BackgroundColor3 = colors[color_background]
	if color_border then
		frame.BorderColor3 = colors[color_border]
		frame.BorderSizePixel = 2
	end
	return frame
end


function Elements.create_pill(parent, text, maxDir)
	local pill = Instance.new("TextLabel", parent)
	pill.BorderSizePixel = 0
	pill.BackgroundColor3 = colors.bg_primary
	pill.Text = text
	pill.TextSize = numbers.font_size
	pill.Font = fonts.font_primary
	local size = text_get_size(`W{text}W`)
	if maxDir == "y" or maxDir == nil then
		pill.Size = UDim2.new(0, size.X, 1, 0)
	elseif maxDir == "x" then
		pill.Size = UDim2.new(1, 0, 0, size.Y)
	end
	local uicorner = Instance.new("UICorner", pill)
	uicorner.CornerRadius = UDim.new(1, 0)
	return pill
end


function Elements.create_button(parent)
	local button = Instance.new("TextButton", parent)
	button.BackgroundTransparency = 1
	button.Modal = true
	button.Size = UDim2.fromScale(1, 1)
	button.Name = "Button"
	button.Text = ""
	return button
end


function Elements.create_list(parent, padding, direction)
	local frame = Elements.create_frame(parent, UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0))
	local listLayout = Instance.new("UIListLayout", frame)
	listLayout.Padding = padding
	listLayout.FillDirection = direction or Enum.FillDirection.Horizontal
	local uiPadding = Instance.new("UIPadding", frame)
	uiPadding.PaddingTop = padding
	uiPadding.PaddingBottom = padding
	uiPadding.PaddingLeft = padding
	uiPadding.PaddingRight = padding
	return frame
end


function Elements.create_scrollbox(parent, size)
	local frame = Instance.new("ScrollingFrame", parent)
	frame.Size = UDim2.fromScale(1, 1)
	frame.CanvasSize = size
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	return frame
end


function Elements.create_grid(parent, padding)
	local frame = Elements.create_frame(parent)
	local actualPadding = padding or udims.padding
	local gridLayout = Instance.new("UIGridLayout", frame)
	listLayout.Padding = actualPadding
	local uiPadding = Instance.new("UIPadding", frame)
	uiPadding.PaddingTop = actualPadding
	uiPadding.PaddingBottom = actualPadding
	uiPadding.PaddingLeft = actualPadding
	uiPadding.PaddingRight = actualPadding
	return frame
end


function Elements.create_image(parent, id)
	local img = Instance.new("ImageLabel", parent)
	img.BackgroundTransparency = 1
	img.Image = `rbxassetid://{id}`
	img.Size = UDim2.fromScale(1, 1)
	img.BorderSizePixel = 0
	return img
end


function Elements.create_text(parent, text, color)
	local label = Instance.new("TextLabel", parent)
	label.BorderSizePixel = 0
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = numbers.font_size
	label.Font = fonts.font_primary
	label.TextColor3 = colors[color or "txt_primary"]
	return label
end


function Elements.create_radio(parent, callback, options)
	local buttons: {Frame} = {}
	local texts: {TextLabel} = {}
	local color_selected = colors.bg_selected
	local color_unselected = colors.bg_unselected
	local text_selected = colors.txt_selected
	local text_unselected = colors.txt_primary
	local runningLength = 0
	local sizes = {}
	for i, option in options do
		local text = option.text or ""
		local size = text_get_size(`W{text}W`)
		if option.image ~= nil then
			size += Vector2.new(size.Y, 0)
		end
		sizes[i] = size
		runningLength += size.X
	end
	
	local container = Elements.create_frame(parent, UDim2.new(0, runningLength, 1, 0))
	local texture = Elements.create_texture(container)
	Elements.style_corner(texture)
	Elements.style_border(texture, color_unselected, 2)
	
	local list = Elements.create_list(texture, UDim.new(0, 0))

	for i, option in options do		
		local frame = Elements.create_frame(list, UDim2.new(0, sizes[i].X, 1, 0))
		frame.BackgroundTransparency = 0
		frame.BackgroundColor3 = color_unselected

		if option.image ~= nil then
			local img = Elements.create_image(frame, option.image)
			img.SizeConstraint = Enum.SizeConstraint.RelativeYY
			img.Size = UDim2.fromScale(1, 1)
		end
		if option.text ~= nil then
			local text = Elements.create_text(frame, option.text)
			text.Size = UDim2.fromScale(1, 1)
			text.TextColor3 = text_unselected
			texts[i] = text
		end
		
		Elements.on_click(frame, function()
			for _, frame in buttons do
				frame.BackgroundColor3 = color_unselected
			end
			for _, text in texts do
				text.TextColor3 = text_unselected
			end
			frame.BackgroundColor3 = color_selected
			if texts[i] then
				texts[i].TextColor3 = text_selected
			end
			callback(option.value)
		end)
		buttons[i] = frame
	end
	
	return container
end


function Elements.create_element_sequence(parent, ...)
	local items = {...}
	
	local container = Elements.create_frame(parent, UDim2.fromScale(1, 1))
	local created_all: {GuiObject} = {}
	local line_height = text_get_size("W").Y * 3
	
	local layout = Instance.new("UIListLayout", container)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Wraps = true
	layout.Padding = udims.padding
	
	local color = Color3.new(1,1,1)
	for i = 1, #items do
		local item = items[i]
		if typeof(item) == "string" then
			local created = Elements.create_text(container, item, "txt_primary")
			created.Size = UDim2.fromOffset(text_get_size(
				item,
				nil,
				created.Font,
				line_height
			).X, line_height)
			created.LayoutOrder = i
			table.insert(created_all, created)
		elseif typeof(item) == "number" then
			local created = Elements.create_image(container, item)
			created.ImageColor3 = color
			created.Size = UDim2.fromOffset(line_height, line_height)
			created.LayoutOrder = i
			table.insert(created_all, created)
		elseif typeof(item) == "Color3" then
			color = item
		end
	end
	
	return container, unpack(created_all)
end


function Elements.clear(instance)
	for _, child in instance:GetChildren() do
		if child:IsA("GuiBase") then
			child:Destroy()
		end
	end
end


function Elements.on_click(instance, callback)
	if instance:IsA("TextButton") then
		instance.MouseButton1Click:Connect(callback)
		return
	end
	local btn = instance:FindFirstChildWhichIsA("TextButton")
	if btn ~= nil then
		btn.MouseButton1Click:Connect(callback)
		return
	end

	local newBtn = Elements.create_button(nil)
	newBtn.Parent = instance
	newBtn.MouseButton1Click:Connect(callback)
end


function Elements.on_press(instance, callback)
	if instance:IsA("TextButton") then
		instance.MouseButton1Down:Connect(callback)
		return
	end
	local btn = instance:FindFirstChildWhichIsA("TextButton")
	if btn ~= nil then
		btn.MouseButton1Down:Connect(callback)
		return
	end

	local newBtn = Elements.create_button(nil)
	newBtn.Parent = instance
	newBtn.MouseButton1Down:Connect(callback)
end


function Elements.style_corner(instance, roundness)
	Instance.new("UICorner", instance).CornerRadius = roundness or UDim.new(1, 0)
end


function Elements.style_line_height(instance)
	instance.Size = UDim2.new(
		instance.Size.X.Scale,
		instance.Size.X.Offset,
		0,
		text_get_size("W").Y * 3
	)
end


function Elements.style_border(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = instance
end


function Elements.style_padding(parent, padding)
	local actualPadding
	if padding == nil then
		actualPadding = udims.padding
	elseif typeof(padding) == "UDim" then
		actualPadding = padding
	elseif typeof(padding) == "string" then
		actualPadding = udims[padding]
	end

	local stroke = Instance.new("UIPadding")
	stroke.PaddingTop = actualPadding
	stroke.PaddingBottom = actualPadding
	stroke.PaddingLeft = actualPadding
	stroke.PaddingRight = actualPadding
	stroke.Parent = parent
end


return true