local replicatedStorage = game:GetService("ReplicatedStorage")

local asset = require(replicatedStorage.Common.Asset.Asset)

local bootloaded_total = 0
local bootloaded_success = 0
local function bootload_folder(folder: Folder)
	for _, module in folder:GetChildren() do
		if module:IsA("ModuleScript") then
			local success = pcall(require, module)
			bootloaded_total += 1
			if success then
				bootloaded_success += 1
			end
		end
	end
end


return function()
	bootload_folder(replicatedStorage.CommonImplementations)
	bootload_folder(replicatedStorage.CommonImplementations.Actor)
	bootload_folder(replicatedStorage.CommonImplementations.Asset)
	bootload_folder(replicatedStorage.CommonImplementations.Data)
	bootload_folder(script.Parent.Implementations)
	bootload_folder(script.Parent.Implementations.Asset)
	bootload_folder(script.Parent.Implementations.Actor)
	bootload_folder(script.Parent.Implementations.Game)
	print(`Succesfully loaded {bootloaded_success}/{bootloaded_total} modules`)

	asset.set_append_from_folder(asset.assets, replicatedStorage.Assets.Models)
	asset.set_append_from_folder(asset.animations, replicatedStorage.Assets.Animations)
	asset.set_append(asset.images, require(replicatedStorage.Assets.Images))
	asset.set_append(asset.translations, require(replicatedStorage.Assets.Translations))
	asset.set_append(asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))
end