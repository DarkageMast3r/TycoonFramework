--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common
local position = require(common.Data.Position)
local actor = require(common.Actor.Actor)
local tr = require(common.Data.TeleoReactive)

export type customer = {
	id: number,
	actor: actor.actor,
	inventory: {[string]: number},
	schedule: {string},
	steps_since_last_action: number,
	actionPosition: position.position,
	program: tr.program_compiled<customer>,
	positions_to_check: {position.position},
	bill_to_pay: number
}

return {
	allCustomers = {}
} :: {
	allCustomers: {customer},
	
	spawn: (pos: position.position, meshName: string, id: number?) -> customer,
	despawn: (customer: customer) -> (),
	add_position_to_check: (c: customer, pos: position.position) -> (),

	get_by_id: (id: number) -> customer?,
	get_by_actor: (actor: actor.actor) -> customer?,
	
	tick: (dt: number) -> (),

	replicate: (c: customer) -> ()
}