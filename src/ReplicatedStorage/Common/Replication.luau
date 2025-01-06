--!strict
export type argument_type =
	"number"
	| "string"
	| "Player"
	| "position"
	| "Vector3"

return {} :: {
	bind_event: (event: RemoteEvent, callback: (...any) -> (), ...argument_type) -> ()
}