export type position = {
	pos: Vector3,
	rot: number,
	plot: Folder?
}

return {} :: {
	is_valid: (pos: any) -> boolean,
	translate: (position, forward: number, right: number, up: number, rot: number) -> position,
	distance: (position, position) -> number,
	object_to_world: (position) -> Vector3,
	object_to_world_cf: (position) -> CFrame,
	world_to_object: (Vector3, plot: Folder?) -> position,
	world_to_object_cf: (CFrame, plot: Folder?) -> position
}