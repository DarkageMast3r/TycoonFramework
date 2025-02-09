--!strict
local serverScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local selection = game:GetService("Selection")
local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Elements = require(contracts.UI.Elements)
local Asset = require(common.Asset.Asset)


if not plugin then
	return
end


local function bootload_folder(folder: Folder, recursive: boolean?)
	for _, module in folder:GetChildren() do
		if module:IsA("Folder") and recursive then
			bootload_folder(module, recursive)
		end
		if module:IsA("ModuleScript") then
			local success = pcall(require, module:Clone())
		end
	end
end

bootload_folder(replicatedStorage.OTF.Client.Implementations.UI, true)
bootload_folder(replicatedStorage.OTF.CommonImplementations, true)
Asset.set_append(Asset.images, require(replicatedStorage.Assets.Images:Clone()))

local toolbar = plugin:CreateToolbar("OTF")


local function style_push()
	Elements.style_push()
	Elements.style_set_color("bg_primary", Color3.new(0.2, 0.2, 0.8))
	Elements.style_set_color("bg_header", Color3.new(0.8, 0.2, 0.2))
	Elements.style_set_color("bg_dark", Color3.new(0.3, 0.3, 0.3))
	Elements.style_set_color("txt_primary", Color3.new(0, 0, 0))
	Elements.style_set_color("txt_unselected", Color3.new(0, 0, 0))
	Elements.style_set_number("font_size", 10)
end
style_push()


local function create_button(name: string, description: string, icon: string, on_active: () -> ())
	local button = toolbar:CreateButton(name, description, icon)
	button.Click:Connect(on_active)
end

local function create_widget(name: string, description: string, icon: string, on_active: (widget: DockWidgetPluginGui) -> ())
	local widget = plugin:CreateDockWidgetPluginGui(
		`OTF-{name}`,
		DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Right, --From what side gui appears
			false, --Widget will be initially enabled
			false, --Don't overdrive previouse enabled state
			200,
			300
		)
	)
	widget.Title = name
	local button = toolbar:CreateButton(name, description, icon)
	button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
		button:SetActive(widget.Enabled)
		if widget.Enabled then
			style_push()
			on_active(widget)
		end
	end)
end


local function module_load(
	name: string,
	module: {
		type: "button" | "widget",
		description: string,
		icon: number,
		on_active: (DockWidgetPluginGui) -> () | () -> ()
	}
)
	local functions = {
		button = create_button,
		widget = create_widget
	}

	functions[module.type](name, module.description, `rbxassedid://{module.icon}`, module.on_active)
end

for _, module in script.Parent:GetChildren() do
	if module:IsA("ModuleScript") then
		module_load(module.Name, require(module:Clone()))
	end
end
