return {} :: {
	create: (
		base: GuiBase,
		type: "edge" | "center",
		size: Vector2,
		colors: {{number}},
		on_click: (x: number, z: number, rot: number) -> ()
	) -> Frame
}