local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common

local cursor = require(contracts.Cursor)
local asset = require(common.Asset.Asset)

local highlight: Model = asset.create_by_name("")

local function highlight_select(name: string)
	highlight:Destroy()
	highlight = asset.create_by_name(name)
	asset.set_uninteractable(highlight)
	highlight.Parent = workspace
end

cursor.tool_register(
	"Delete",
	function()
		highlight_select("Highlight.Delete")
	end,
	function()
		highlight_select("")
	end,
	function()
		
	end,
	function()
		local cursor_hit = cursor.current.hit_instance
		if cursor_hit == nil then
			return
		end
		repeat
			cursor_hit = cursor_hit.Parent
		until cursor_hit.Parent == nil or cursor_hit:IsA("Model")
		if cursor_hit.Parent == nil then
			return
		end

		replicatedStorage.Remotes.PlotDeleteEvent:FireServer(
			cursor.current.pos.pos,
			cursor.current.pos,
			asset.resolve_type(cursor_hit.Name),
			"single"
		)
	end,
	function()
		cursor.update_location(true)
		asset.move_to(highlight, cursor.current.pos)
	end
)

return true