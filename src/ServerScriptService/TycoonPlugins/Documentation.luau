--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common

local Elements = require(contracts.UI.Elements)
local Asset = require(common.Asset.Asset)

type topic = {
	title: string,
	description: string
}

local topics: {topic} = {
	{
		title = "Asset selection",
		description = [[
All assets are selected through a tag name system.
An asset may be named, for instance, Floor.Wood.Dark.Grime
When selecting the appropiate model for this asset, the system will first look for Floor.Wood.Dark.Grime
If it does not find this, it will remove everything after the last '.', and look again. This will continue until the appropiate model is found.
In the second iteration, it might look for a model named Floor.Wood.Dark.
In the third iteration, it will look Floor.Wood, and in the fourth for Floor.
In the fifth iteration, it will look for "". All asset sets are required to contain an asset by the name of "", ensuring that an asset is always returned.

This system removes any potential errors related to creating a model, or anything else that uses the asset system, such as images, animations, item price info, etc.
The model asset set contains a sample model for for every layer, meaning a sample model for Wall_Outer, Wall_Inner, Floor, Ceiling, Asset, etc.
These sample models emulate the rough expected shape for each layer, but making it clear that the appropiate model has not been found.
Additionally, the "" model contains a black cube with question marks on all sides, indicating a great failure in asset selection.

The model asset system contains a special case, where creating the model "" results in an empty model, but creating a model which gets evaluated to "" returns the black cube.
]]
	}
}

local frame

local screens = {}

local function create_topbar(parent)
	local frame_topbar = Elements.create_background(
		Elements.create_frame(parent, UDim2.new(1, 0, 0, 30)),
		"bg_header", "bg_dark"
	)
	Elements.create_list(frame_topbar, UDim.new(0, 5), Enum.FillDirection.Horizontal)
	Elements.style_flex(frame_topbar, 0, 0)
	return frame_topbar
end


function screens.topic(topic: topic)
	frame:ClearAllChildren()
	local root = Elements.create_list(frame, UDim.new(0, 0), Enum.FillDirection.Vertical)

	local frame_topbar = create_topbar(root)
	
	local btn_return = Elements.create_image(frame_topbar, Asset.set_fetch(Asset.images, "Icon.Arrow.Left"))
	Elements.style_ratio(btn_return, 1)
	Elements.style_flex(btn_return, 0, 0)

	local frame_title = Elements.create_frame(frame_topbar, UDim2.new(1, 0, 1, 0))
	Elements.create_text(frame_title, topic.title)
	
	local frame_content = Elements.create_frame(root)
	Elements.style_padding(frame_content)
	Elements.style_flex(btn_return, 1, 0)

	local scrollframe_content = Elements.create_scrollbox(frame_content, UDim2.new(1, 0, 0, 1000))
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.TextWrapped = true
	text.Text = topic.description
	text.BorderSizePixel = 0
	text.BackgroundTransparency = 1
	text.Parent = scrollframe_content

	Elements.on_click(btn_return, function()
		screens.topics()
	end)
end


function screens.topics()
	frame:ClearAllChildren()
	local root = Elements.create_list(frame, UDim.new(0, 0), Enum.FillDirection.Vertical)
	local frame_topbar = create_topbar(root)
	local text = Elements.create_text(frame_topbar, "Topics")
	Elements.style_flex(text, 1, 0)

	local frame_content = Elements.create_scrollbox(root, UDim2.new(1, 0, 0, 1000))
	Elements.style_flex(frame_content, 1, 0)


	local lst_topics = Elements.create_list(frame_content, UDim.new(0, 5), Enum.FillDirection.Vertical)

	for _, topic in topics do
		local topic_frame = Elements.create_frame(lst_topics)
		Elements.style_line_height(topic_frame)
		Elements.style_border(topic_frame, Color3.new(0.3, 0.3, 0.3), 1)
		local topic_btn = Elements.create_text(topic_frame, topic.title)
		Elements.on_click(topic_btn, function()
			screens.topic(topic)
		end)
	end
end


local function on_active(widget)
	widget:ClearAllChildren()
	frame = Elements.create_frame(widget)
	screens.topics()
end


return {
	type = "widget",
	description = "View documentation of all systems",
	icon = 8740888472,
	on_active = on_active
}