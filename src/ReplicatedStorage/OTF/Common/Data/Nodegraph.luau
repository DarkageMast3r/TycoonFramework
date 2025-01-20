--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common

local Plot = require(common.Plot)

export type node<t> = {
	value: t,
	edges: {[node<t>]: number},
	next: node<t>?,
	distance: number
}

export type nodegraph<t> = {
	nodes: {node<t>},
	layer_indices: {
		{node<t>}
	}
}

return {} :: {
	pathfind_astar: <t>(nodegraph<t>, from: node<t>, to: node<t>, heuristic: (t, t) -> number) -> {t},
	pathfind_dijkstra: <t>(nodegraph<t>, from: node<t>, to: node<t>) -> {t},
	node_connect: <t>(a: node<t>, b: node<t>, heuristic: (t, t) -> number) -> (),
	node_create: <t>(value: t) -> node<t>,
	visualise: (nodegraph<Vector3>, p: Plot.plot, buffer: {Instance}) -> ()
}