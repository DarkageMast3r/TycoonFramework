--!strict
export type layer_serialized = {
	name: string,
	type: string,
	height: number,
	size: {
		x: number,
		z: number
	},
	assets: {string}
}

export type plot_serialized = {
	layers: {layer_serialized}
}

export type data = {
	currency: number
}

return {} :: {
	load_data: (player: Player) -> data,
	load_plot: (player: Player) -> plot_serialized
}