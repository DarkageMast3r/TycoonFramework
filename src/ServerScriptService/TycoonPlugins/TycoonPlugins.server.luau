--!strict
local serverScriptService = game:GetService("ServerScriptService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local starterPlayer = game:GetService("StarterPlayer")
local selection = game:GetService("Selection")
local contracts = replicatedStorage.OTF.Client.Contracts
local Elements = require(contracts.UI.Elements)


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

print("Bootloading plugin")
bootload_folder(replicatedStorage.OTF.Client.Implementations.UI, true)


local toolbar = plugin:CreateToolbar("OTF")


local function create_button(name: string, description: string, icon: string, on_active: () -> ())
	print("Button", name, description, icon)
	local button = toolbar:CreateButton(name, description, icon)
	button.Click:Connect(on_active)
end

local function create_widget(name: string, description: string, icon: string, on_active: (widget: DockWidgetPluginGui) -> ())
	print("Widget", name, description, icon)
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


Elements.style_push()
Elements.style_set_color("bg_primary", Color3.new(1, 1, 1))
Elements.style_set_color("txt_primary", Color3.new(0, 0, 0))
Elements.style_set_color("txt_unselected", Color3.new(0, 0, 0))
Elements.style_set_number("font_size", 10)

for _, module in script.Parent:GetChildren() do
	if module:IsA("ModuleScript") then
		module_load(module.Name, require(module))
	end
end
