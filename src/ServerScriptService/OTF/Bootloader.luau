local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local common = replicatedStorage.OTF.Common
local Asset = require(common.Asset.Asset)

local bootloaded_total = 0
local bootloaded_success = 0
local function bootload_folder(folder: Folder, recursive: boolean?)
	for _, module in folder:GetChildren() do
		if module:IsA("Folder") and recursive then
			bootload_folder(module, recursive)
		end
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
	bootload_folder(serverScriptService.OTF, true)
	bootload_folder(serverScriptService.Custom, true)
	bootload_folder(replicatedStorage.OTF.CommonImplementations, true)
	print(`Succesfully loaded {bootloaded_success}/{bootloaded_total} modules`)

	Asset.set_append_from_folder(Asset.assets, replicatedStorage.Assets.Models)
	Asset.set_append_from_folder(Asset.animations, replicatedStorage.Assets.Animations)
	Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images))
	Asset.set_append(Asset.translations, require(replicatedStorage.Assets.Translations))
	Asset.set_append(Asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))
end