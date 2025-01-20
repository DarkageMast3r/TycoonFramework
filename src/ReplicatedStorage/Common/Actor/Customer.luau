--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local Position = require(common.Data.Position)
local Actor = require(common.Actor.Actor)
local Tr = require(common.Data.TeleoReactive)

export type customer = {
	id: number,
	actor: Actor.actor,
	inventory: {[string]: number},
	schedule: {string},
	steps_since_last_action: number,
	actionPosition: Position.position,
	program: Tr.program_compiled<customer>,
	positions_to_check: {Position.position},
	bill_to_pay: number
}

return {
	allCustomers = {}
} :: {
	allCustomers: {customer},
	
	spawn: (pos: Position.position, meshName: string, id: number?) -> customer,
	despawn: (customer: customer) -> (),
	add_position_to_check: (c: customer, pos: Position.position) -> (),

	get_by_id: (id: number) -> customer?,
	get_by_actor: (actor: Actor.actor) -> customer?,
	
	tick: (dt: number) -> (),

	replicate: (c: customer) -> ()
}