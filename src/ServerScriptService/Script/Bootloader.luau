local replicatedStorage = game:GetService("ReplicatedStorage")

local Asset = require(replicatedStorage.Common.Asset.Asset)

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

	Asset.set_append_from_folder(Asset.assets, replicatedStorage.Assets.Models)
	Asset.set_append_from_folder(Asset.animations, replicatedStorage.Assets.Animations)
	Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images))
	Asset.set_append(Asset.translations, require(replicatedStorage.Assets.Translations))
	Asset.set_append(Asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))
end