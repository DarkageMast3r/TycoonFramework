--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.OTF.Client.Contracts
local common = replicatedStorage.OTF.Common
local Elements = require(contracts.UI.Elements)
local Grid = require(contracts.UI.Grid)


local function cell_create_center(colors: {Color3}, on_click: (rot: number) -> ()): Frame
	local frame = Elements.create_frame()
	frame.BackgroundColor3 = colors[1]
	frame.BackgroundTransparency = 0
	Elements.on_press(frame, function(x, y)
		on_click(0)
	end)
end


local function cell_create_edge(colors: {Color3}, on_click: (rot: number) -> ()): Frame
	local frame = Elements.create_frame()
	for rot = 0, 3 do
		local img = Elements.create_image(frame, 96753806776558)
		img.Rotation = rot * -90
		img.ImageColor3 = colors[rot + 1]
	end
	
	Elements.on_press(frame, function(x, y)
		x -= frame.AbsolutePosition.X
		y -= frame.AbsolutePosition.Y
		local rot = 0
		if x > y then
			if x + y > imgsize then
				rot = 3
			else
				rot = 0
			end
		else
			if x + y > imgsize then
				rot = 2
			else
				rot = 1
			end
		end
		on_click(rot)
	end)
end


local grid_types = {
	center = {
		cell_create = cell_create_center,
		colors = 1
	},
	edge = {
		cell_create = cell_create_edge,
		colors = 4
	}
}

function Grid.create(base, type, size, colors, on_click)
	local container = Elements.create_grid(base)
	colors = table.clone(colors)

	for x = 0, size.X-1 do
		for y = 0, size.Y-1 do
			local cell = Elements.create_frame(container)
			grid_types[type].cell_create(colors, function(rot)
				on_click(x, y, rot)
			end)
			for i = 1, grid_types[type].colors do
				table.remove(colors, 1)
			end
		end
	end
	return container
end


return true