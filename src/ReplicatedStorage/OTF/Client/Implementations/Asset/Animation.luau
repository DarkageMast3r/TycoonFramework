--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Animation = require(common.Asset.Animation)
local Asset = require(common.Asset.Asset)


local function animator_get_or_create(model: Model)
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	local animationController = model:FindFirstChildWhichIsA("AnimationController")
	local parent: Instance? = humanoid or animationController
	if parent == nil then
		parent = Instance.new("AnimationController", model)
	end
	
	if parent == nil then
		error("???")
	end
	local animator = parent:FindFirstChildWhichIsA("Animator")
	if animator ~= nil then
		return animator
	end
	return Instance.new("Animator", parent)
end


function Animation.create_by_name(model, name)
	local asset = Asset.set_fetch(Asset.animations, name)
	local animator = animator_get_or_create(model)
	return animator:LoadAnimation(asset)
end


return true