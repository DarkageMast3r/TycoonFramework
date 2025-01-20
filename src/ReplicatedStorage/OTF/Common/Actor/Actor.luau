--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common
local Position = require(common.Data.Position)

export type animation_type = "idle" | "walk"

export type actor_state = {
	init: (a: actor) -> (),
	update: (a: actor, dt: number) -> ()
}

export type actor = {
	id: number,
	state: string,
	position: Position.position,
	target: Position.position?,
	path: {Position.position},
	speed: number,
	mesh: Model?,
	meshName: string,
	animations: {[string]: AnimationTrack},
	waypoint_reached: BindableEvent,
	target_reached: BindableEvent
}

return {
	states = {}	
} :: {
	allActors: {actor},
	
	create: (pos: Position.position, meshName: string, id: number?) -> actor,
	spawn: (pos: Position.position, meshName: string, id: number?) -> actor,
	despawn: (actor: actor) -> (),
	
	animation_load: (actor: actor, type: animation_type, name: string) -> (),
	animation_play: (actor: actor, type: animation_type, fadeTime: number?) -> (),
	
	walk_to: (actor: actor, pos: Position.position, path: {Position.position}?) -> (),
	
	get_in_plot: (origin: Position.position) -> {actor},
	get_in_box: (origin: Position.position, size: Vector3) -> {actor},
	get_in_radius: (origin: Position.position, radius: number) -> {actor},
	get_by_id: (id: number) -> actor?,
	
	states: {[string]: actor_state},
	switch_to_state: (a: actor, state: string) -> (),
	
	replicate: (a: actor) -> (),
	
	tick: (dt: number) -> ()
}