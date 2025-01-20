local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")

local common = replicatedStorage.OTF.Common
local Asset = require(common.Asset.Asset)

local bootloaded_total = 0
local bootloaded_success = 0


local OTF = {
	Actor = require(common.Actor.Actor),
	Asset = {
		Asset = require(common.Asset.Asset),
		Animation = require(common.Asset.Animation)
	},
	Data = {
		NodeGraph = require(common.Data.Nodegraph),
		Position = require(common.Data.Position),
		Program = require(common.Data.Program),
		TeleoReactive = require(common.Data.TeleoReactive)
	},
	Game = {
		Tycoon = require(common.Game.Tycoon)
	},
	Config = require(common.Config),
	DragModes = require(common.DragModes),
	Plot = require(common.Plot),
	Replication = require(common.Replication),
	
}


function OTF.bootload_folder(container: Instance, recursive: boolean?)
	for _, module in (recursive and container:GetDescendants() or container:GetChildren()) :: {Instance} do
		if module:IsA("ModuleScript") then
			local success = pcall(require, module)
			bootloaded_total += 1
			if success then
				bootloaded_success += 1
			end
		end
	end
end

function OTF.load()
	OTF.bootload_folder(serverScriptService.OTF.Implementations, true)
	OTF.bootload_folder(replicatedStorage.OTF.CommonImplementations, true)
	print(`Succesfully loaded {bootloaded_success}/{bootloaded_total} modules`)
 
	Asset.set_append_from_folder(Asset.assets, replicatedStorage.Assets.Models)
	Asset.set_append_from_folder(Asset.animations, replicatedStorage.Assets.Animations)
	Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images))
	Asset.set_append(Asset.translations, require(replicatedStorage.Assets.Translations))
	Asset.set_append(Asset.assetInfo, require(replicatedStorage.Assets.AssetInfo))
end


return OTF