local replicatedStorage = game:GetService("ReplicatedStorage")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common

local Cursor = require(contracts.Cursor)
local Asset = require(common.Asset.Asset)

local highlight: Model = Asset.create_by_name("")

local function highlight_select(name: string)
	highlight:Destroy()
	highlight = Asset.create_by_name(name)
	Asset.set_uninteractable(highlight)
	highlight.Parent = workspace
end

Cursor.tool_register(
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
		local cursor_hit = Cursor.current.hit_instance
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
			Cursor.current.pos.pos,
			Cursor.current.pos,
			Asset.resolve_type(cursor_hit.Name),
			"single"
		)
	end,
	function()
		Cursor.update_location(true)
		Asset.move_to(highlight, Cursor.current.pos)
	end
)

return true