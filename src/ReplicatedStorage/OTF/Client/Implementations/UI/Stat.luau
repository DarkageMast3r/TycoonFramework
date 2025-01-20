--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local textService = game:GetService("TextService")
local runService = game:GetService("RunService")
local textService = game:GetService("TextService")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Elements = require(contracts.UI.Elements)
local Asset = require(common.Asset.Asset)


local stat_counters: {[string]: TextLabel} = {}

function Elements.create_stat(parent, name)
	local container, icon, text = Elements.create_element_sequence(
		parent,
		Color3.fromRGB(71, 159, 74),
		Asset.set_fetch(Asset.images, `Icon.{name}`),
		"0"
	)
	Elements.style_corner(container)
	Elements.style_line_height(container)
	container.BackgroundTransparency = 0
	container.BackgroundColor3 = Color3.new(1,1,1)
	stat_counters[name] = text :: TextLabel
	return container
end

if runService:IsClient() then
	replicatedStorage.Remotes.StatEvent.OnClientEvent:Connect(function(stat, value)
		if stat_counters[stat] == nil then
			return
		end
		local textLabel = stat_counters[stat]
		textLabel.Text = tostring(value)
		local textSize = textService:GetTextSize(
			textLabel.Text,
			textLabel.TextSize,
			textLabel.Font,
			Vector2.new(math.huge, math.huge)
		)
		textLabel.Size = UDim2.new(
			0,
			textSize.X,
			textLabel.Size.Y.Scale,
			textLabel.Size.Y.Offset
			
		)
	end)
end

return true