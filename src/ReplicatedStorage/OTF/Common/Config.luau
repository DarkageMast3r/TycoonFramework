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
	},
	transformation_rules = {
		{
			include = {
				floor = {
					[{0, 0, 0, 0}] = "Wood"
				}
			},
			exclude = {},
			modifier = "Trim",
			layer = "wall_outer"
		},
		{
			include = {
				floor = {
					[{0, 0, 0, 1}] = "Wood"
				}
			},
			exclude = {},
			modifier = "Trim",
			layer = "wall_outer"
		},
		{
			include = {
				floor = {
					[{0, 0, 0, 2}] = "Wood"
				}
			},
			exclude = {},
			modifier = "Trim",
			layer = "wall_outer"
		},
		{
			include = {
				floor = {
					[{0, 0, 0, 3}] = "Wood"
				}
			},
			exclude = {},
			modifier = "Trim",
			layer = "wall_outer"
		},
		{
			include = {
				wall_inner = {
					[{0, 0, 0, 0}] = "DoorSingle"
				}
			},
			exclude = {},
			modifier = "DoorSingle",
			layer = "wall_outer"
		},
		{
			include = {
				wall_inner = {
					[{1, 0, 0, 2}] = "DoorSingle"
				}
			},
			exclude = {},
			modifier = "DoorSingle",
			layer = "wall_outer"
		},
		{
			include = {
				wall_inner = {
					[{0, 0, 0, 0}] = "Window"
				}
			},
			exclude = {},
			modifier = "Window",
			layer = "wall_outer"
		},
		{
			include = {
				wall_inner = {
					[{1, 0, 0, 2}] = "Window"
				}
			},
			exclude = {},
			modifier = "Window",
			layer = "wall_outer"
		}
	}
}