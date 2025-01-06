--!strict
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local plot = require(common.Plot)
local cursor = require(contracts.Cursor)
local actionManager = require(contracts.ActionManager)
local toolbar = require(contracts.UI.Toolbar)
local elements = require(contracts.UI.Elements)
local asset = require(common.Asset.Asset)

local lst_toolbar = script.Parent.Toolbar
local lst_topbar = script.Parent.Topbar

elements.style_set_color("bg_primary", Color3.new(1, 1, 1))
elements.style_set_color("txt_primary", Color3.new(0, 0, 0))
elements.style_set_color("txt_unselected", Color3.new(0, 0, 0))
elements.style_set_number("font_size", 10)

local lst_stats = elements.create_list(script.Parent.Stats, UDim.new(0, 5), Enum.FillDirection.Vertical)
elements.create_stat(lst_stats, "currency")

local btn_select_floor = elements.create_pill(lst_topbar, "Floors")
local btn_select_walls = elements.create_pill(lst_topbar, "Walls")
local btn_select_ceilings = elements.create_pill(lst_topbar, "Ceilings")
local btn_select_assets = elements.create_pill(lst_topbar, "Assets")
local btn_select_decorations = elements.create_pill(lst_topbar, "Decorations")
local btn_build = elements.create_pill(lst_topbar, "Build")
local btn_delete = elements.create_pill(lst_topbar, "Delete")
local sl_dragmodes = elements.create_radio(lst_topbar, cursor.set_state_dragmode, {
	{value = "square", image = 0, text = "Square"},
	{value = "line", image = 0, text = "Line"},
	{value = "single", image = 0, text = "Single"}
})

elements.on_click(btn_select_floor, function()
	toolbar.fill(lst_toolbar, {
		"Floor.Wood",
		"Floor.Wood.Dark",
		"Floor.Carpet.Red",
		"Floor.Carpet.Blue",
		"Floor.Marble",
		"Floor.Asphalt",
		"Floor.Concrete",
		"Floor.Concrete.Dark",
		"Floor.Grass",
		"Floor.Grass.Leaves"
	}, function(name)
		cursor.set_state_build()
		cursor.asset_select(name)
	end)
end)
elements.on_click(btn_select_walls, function()
	toolbar.fill(lst_toolbar, {
		"Wall_Outer.Brick",
		"Wall_Outer.Plaster",
		"Wall_Outer.Plaster.Trim",
		"Wall_Outer.Brick.Ledge",
		"Wall_Outer.Concrete.Ledge"
	}, function(name)
		cursor.set_state_build()
		cursor.asset_select(name)
	end)
end)
elements.on_click(btn_select_ceilings, function()
	toolbar.fill(lst_toolbar, {
		"Ceiling.Concrete",
		"Ceiling.Concrete.Dark",
		"Ceiling.Glass",
		"Light.Square"
	}, function(name)
		cursor.set_state_build()
		cursor.asset_select(name)
	end)
end)
elements.on_click(btn_select_decorations, function()
	toolbar.fill(lst_toolbar, {
		"Wall_Inner.DoorSingle.Red",
		"Wall_Inner.DoorSingle.Green",
		"Wall_Inner.DoorSingle.Blue",
		"Wall_Inner.DoorSingle.Wood",
		"Wall_Inner.Window",
		"Wall_Inner.Painting",
		"Wall_Inner.Painting.MonaLisa",
	}, function(name)
		cursor.set_state_build()
		cursor.asset_select(name)
	end)
end)
elements.on_click(btn_select_assets, function()
	toolbar.fill(lst_toolbar, {
		"Asset.Chair",
		"Asset.Table",
		"Asset.Table.Corner",
	}, function(name)
		cursor.set_state_build()
		cursor.asset_select(name)
	end)
end)
elements.on_click(btn_build, cursor.set_state_build)
elements.on_click(btn_delete, cursor.set_state_delete)

replicatedStorage.Remotes.StatEvent:FireServer()