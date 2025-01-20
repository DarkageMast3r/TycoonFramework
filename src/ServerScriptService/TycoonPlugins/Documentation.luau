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

function screens.topic(topic: topic)
	frame:ClearAllChildren()
	local frame_topbar = Elements.create_background(
		Elements.create_frame(frame, UDim2.new(1, 0, 0, 30)),
		"bg_header", "bg_dark"
	)
	Elements.style_line_height(frame_topbar)
	Elements.style_padding(frame_topbar)
	
	local frame_content = Elements.create_frame(frame, UDim2.new(1, 0, 1, -30), UDim2.fromOffset(0, 30))
	Elements.style_padding(frame_content)
	local _, btn_return = Elements.create_element_sequence(
		frame_topbar,
		Asset.set_fetch(Asset.images, "Icon.Arrow.Right"),
		topic.title
	)
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
	frame:Clone().Parent = workspace
end


function screens.topics()
	frame:ClearAllChildren()
	local lst_topics = Elements.create_list(frame, UDim.new(0, 5), Enum.FillDirection.Vertical)
	for _, topic in topics do
		local topic_btn = Elements.create_text(lst_topics, topic.title)
		Elements.style_line_height(topic_btn)
		topic_btn.Size = UDim2.new(1, 0, 0, topic_btn.Size.Y.Offset * 3)
		Elements.on_click(topic_btn, function()
			print("Clicked!")
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