--!strict
local contextActionService = game:GetService("ContextActionService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local Cursor = require(contracts.Cursor)
local Toolbar = require(contracts.UI.Toolbar)
local Elements = require(contracts.UI.Elements)

local lst_toolbar = script.Parent.Toolbar
local lst_topbar = script.Parent.Topbar

Elements.style_set_color("bg_primary", Color3.new(1, 1, 1))
Elements.style_set_color("txt_primary", Color3.new(0, 0, 0))
Elements.style_set_color("txt_unselected", Color3.new(0, 0, 0))
Elements.style_set_number("font_size", 10)

local lst_stats = Elements.create_list(script.Parent.Stats, UDim.new(0, 5), Enum.FillDirection.Vertical)
Elements.create_stat(lst_stats, "currency")

local btn_select_floor = Elements.create_pill(lst_topbar, "Floors")
local btn_select_walls = Elements.create_pill(lst_topbar, "Walls")
local btn_select_ceilings = Elements.create_pill(lst_topbar, "Ceilings")
local btn_select_assets = Elements.create_pill(lst_topbar, "Assets")
local btn_select_decorations = Elements.create_pill(lst_topbar, "Decorations")
local btn_build = Elements.create_pill(lst_topbar, "Build")
local btn_delete = Elements.create_pill(lst_topbar, "Delete")
local sl_dragmodes = Elements.create_radio(lst_topbar, Cursor.set_state_dragmode, {
	{value = "square", image = 0, text = "Square"},
	{value = "line", image = 0, text = "Line"},
	{value = "single", image = 0, text = "Single"}
})

Elements.on_click(btn_select_floor, function()
	Toolbar.fill(lst_toolbar, {
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
		Cursor.set_state_build()
		Cursor.asset_select(name)
	end)
end)
Elements.on_click(btn_select_walls, function()
	Toolbar.fill(lst_toolbar, {
		"Wall_Outer.Brick",
		"Wall_Outer.Plaster",
		"Wall_Outer.Brick.Ledge",
		"Wall_Outer.Concrete.Ledge"
	}, function(name)
		Cursor.set_state_build()
		Cursor.asset_select(name)
	end)
end)
Elements.on_click(btn_select_ceilings, function()
	Toolbar.fill(lst_toolbar, {
		"Ceiling.Concrete",
		"Ceiling.Concrete.Dark",
		"Ceiling.Glass",
		"Light.Square"
	}, function(name)
		Cursor.set_state_build()
		Cursor.asset_select(name)
	end)
end)
Elements.on_click(btn_select_decorations, function()
	Toolbar.fill(lst_toolbar, {
		"Wall_Inner.DoorSingle.Red",
		"Wall_Inner.DoorSingle.Green",
		"Wall_Inner.DoorSingle.Blue",
		"Wall_Inner.DoorSingle.Wood",
		"Wall_Inner.Window",
		"Wall_Inner.Painting",
		"Wall_Inner.Painting.MonaLisa",
	}, function(name)
		Cursor.set_state_build()
		Cursor.asset_select(name)
	end)
end)
Elements.on_click(btn_select_assets, function()
	Toolbar.fill(lst_toolbar, {
		"Asset.Chair",
		"Asset.Table",
		"Asset.Table.Corner",
		"Asset.Checkout",
		"Asset.Drawer",
	}, function(name)
		Cursor.set_state_build()
		Cursor.asset_select(name)
	end)
end)
Elements.on_click(btn_build, Cursor.set_state_build)
Elements.on_click(btn_delete, Cursor.set_state_delete)

replicatedStorage.Remotes.StatEvent:FireServer()