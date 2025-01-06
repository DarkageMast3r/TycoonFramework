--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local position = require(common.Data.Position)

export type cursor = {
	pos: position.position,
	type: string,
	asset: string,
	hit_instance: Instance?,
	dragmode: string
}


return {} :: {
	current: cursor,
	asset_select: (name: string) -> (),
	update: () -> (),
	update_location: (select_hit_instance: boolean) -> (),

	set_state_build: () -> (),
	set_state_delete: () -> (),
	set_state_dragmode: (mode: string) -> (),
	
	tool_select: (tool: string) -> (),
	tool_action_begin: () -> (),
	tool_action_end: () -> (),
	tool_register: (
		tool: string,
		load: () -> (),
		unload: () -> (),
		action_begin: () -> (),
		action_end: () -> (),
		update: () -> ()
	) -> ()
}