return {
	behaviour = {
		plots_are_persistent = false
	},
	cell = {
		size = Vector3.new(4, 9, 4)
	},
	plot = {
		layers = {
			floor = "center",
			wall_inner = "edge",
			wall_outer = "edge",
			ceiling = "center",
			asset = "edge",
			light = "edge"
		} :: {[string]: ("center" | "edge")},
		layer_count = 1
	}
}