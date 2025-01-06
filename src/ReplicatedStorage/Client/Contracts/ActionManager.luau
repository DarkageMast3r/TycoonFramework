--!strict

return {} :: {
	register: (name: string, mode: "press" | "release", callback: (pressed: boolean) -> ()) -> (),
	bind: (name: string, ...Enum.UserInputType|Enum.KeyCode) -> ()
}