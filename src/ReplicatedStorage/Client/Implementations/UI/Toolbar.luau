--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local Elements = require(contracts.UI.Elements)
local Toolbar = require(contracts.UI.Toolbar)
local Asset = require(common.Asset.Asset)

function Toolbar.fill(base, assets, callback)
	Elements.clear(base)
	Elements.style_push()
	Elements.style_set_color("txt_primary", Color3.new(1,1,1))
	for _, asset in assets do
		local viewport = Elements.viewport.create_asset(asset)
		local currencyCounterBg = Elements.create_frame(viewport)
		currencyCounterBg.Size = UDim2.new(1, 0, 0, 25)
		currencyCounterBg.AnchorPoint = Vector2.new(0, 1)
		currencyCounterBg.Position = UDim2.fromScale(0, 1)
		currencyCounterBg.BackgroundTransparency = 0.5
		currencyCounterBg.BackgroundColor3 = Color3.new(0, 0, 0)
		
		local currencyCounter = Elements.create_element_sequence(
			currencyCounterBg,
			Color3.fromRGB(71, 159, 74),
			Asset.set_fetch(Asset.images, "Icon.Currency"),
			tostring(Asset.set_fetch(Asset.assetInfo, asset).price)
		)
		
		Elements.on_click(viewport, function()
			callback(asset)
		end)
		viewport.Parent = base
	end
	Elements.style_pop()
end

return true