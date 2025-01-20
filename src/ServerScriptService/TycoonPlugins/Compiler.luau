--!strict
local serverScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local selection = game:GetService("Selection")
local contracts = replicatedStorage.OTF.Client.Contracts
local Elements = require(contracts.UI.Elements)

local month_codes = {
	"jan", "feb", "mar",
	"apr", "may", "jun",
	"jul", "aug", "sep",
	"oct", "nov", "dec"
}
local function compile_release()
	local date = DateTime.now():ToUniversalTime()
	local release = Instance.new("Folder")
	release.Name = `Release {date.Year} {month_codes[date.Month]} {date.Day} @ {date.Hour}:{string.format("%.2d", date.Minute)}`

	local items_to_store = {
		replicatedStorage.Assets,
		replicatedStorage.OTF,
		replicatedStorage.Remotes,
		serverScriptService.OTF,
		serverScriptService.TycoonPlugins,
		serverScriptService.Custom,
		serverScriptService.Script,
		starterGui.ScreenGui,
		starterPlayer.StarterPlayerScripts.LocalScript
	}
	local src_lines = {}
	table.insert(src_lines, `local release = workspace["{release.Name}"]`)
	for _, item in items_to_store do
		repeat
			item = item.Parent
		until item.Parent == game
		if not release:FindFirstChild(item.ClassName) then
			table.insert(src_lines, `local {item.ClassName} = game:GetService("{item.ClassName}")`)
			Instance.new("Folder", release).Name = item.ClassName
		end
	end

	for _, item in items_to_store do
		local service = item
		repeat
			service = service.Parent
		until service.Parent == game
		item:Clone().Parent = release:WaitForChild(service.ClassName)
		table.insert(src_lines, `release["{service.ClassName}"]["{item.Name}"].Parent = {item.Parent:GetFullName()}`)
	end
	table.insert(src_lines, "release:Destroy()")

	local installer = Instance.new("Script")
	installer.Source = table.concat(src_lines, "\n")
	installer.Name = "Installer"
	installer.Parent = release

	release.Parent = workspace
	selection:Set({release})
end


return {
	type = "button",
	description = "Compile OTF for public distribution",
	icon = 8740888472,
	on_active = compile_release
}