--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.Common

local Position = require(common.Data.Position)
local NodeGraph = require(common.Data.Nodegraph)


local function dequeue<t>(haystack: {{value: t, priority: number}}): t?
	local selected = haystack[1]
	local idx = 1
	if selected == nil then
		return nil
	end
	for i, v in haystack do
		if v.priority < selected.priority then
			selected = v
			idx = i
		end
	end
	table.remove(haystack, idx)
	return selected.value
end


local function try_insert<t>(haystack: {{value: t, priority: number}}, needle: t, priority: number)
	for _, item in haystack do
		if item.value == needle then
			return
		end
	end
	table.insert(haystack, {value = needle, priority = priority})
end


function NodeGraph.pathfind_dijkstra<t>(nodegraph, from: NodeGraph.node<t>, to: NodeGraph.node<t>): {t}
	local nodes = nodegraph.nodes
	for _, node in nodes do
		node.distance = math.huge
		node.next = nil
	end

	to.distance = 0
	local open = {}
	try_insert(open, to, 0)
	local closed = {}
	repeat
		local cur = dequeue(open)
		if cur == nil then
			break
		end
		for other, distance in cur.edges do
			if cur.distance + distance < other.distance then
				other.next = cur
				other.distance = cur.distance + distance
				try_insert(open, other, other.distance)
			end
		end
	until open[1] == nil
	local nodes = {}
	local cur: NodeGraph.node<t>? = from
	repeat
		if cur ~= nil then
			table.insert(nodes, cur.value)
			cur = cur.next
		end
	until cur == nil
	table.insert(nodes, to.value)
	return nodes
end


function NodeGraph.pathfind_astar<t>(nodegraph, from: NodeGraph.node<t>, to: NodeGraph.node<t>, heuristic: (t, t) -> number): {t}
	local nodes = nodegraph.nodes
	for _, node in nodes do
		node.distance = math.huge
		node.next = nil
	end

	to.distance = 0
	local open = {}
	try_insert(open, to, 0)
	local closed = {}
	repeat
		local cur = dequeue(open)
		if cur == nil then
			break
		end
		if cur == from then
			break
		end
		for other, distance in cur.edges do
			local newDistance = cur.distance + distance + heuristic(cur.value, from.value)
			if newDistance < other.distance then
				other.next = cur
				other.distance = newDistance
				try_insert(open, other, other.distance + heuristic(cur.value, from.value))
			end
		end
	until open[1] == nil
	local nodes = {}
	local cur: NodeGraph.node<t>? = from
	repeat
		if cur ~= nil then
			table.insert(nodes, cur.value)
			cur = cur.next
		end
	until cur == nil
--	table.insert(nodes, to.value)
	return nodes
end


function NodeGraph.node_connect(a, b, heuristic)
	local distance = heuristic(a.value, b.value)
	a.edges[b] = distance
	b.edges[a] = distance
end


function NodeGraph.node_create(value)
	return {
		value = value,
		edges = {},
		next = nil,
		distance = math.huge
	}
end


function NodeGraph.visualise(graph, p, buffer)
	for _, p in buffer do
		p:Destroy()
	end

	for _, node in graph.nodes do
		local pos = node.value
		local start = Position.object_to_world({pos = pos, rot = 0, plot = p.folder}) + Vector3.new(0, 2, 0)
		local part = Instance.new("Part")
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Anchored = true
		part.Size = Vector3.new(0.5, 0.5, 0.5)
		part.CFrame = CFrame.new(start)
		part.Color = Color3.fromRGB(86, 81, 166)
		part.Parent = workspace
		table.insert(buffer, part)
		for edge in node.edges do
			local to = edge.value
			local target = Position.object_to_world({pos = to, rot = 0, plot = p.folder}) + Vector3.new(0, 2, 0)

			local node = Instance.new("Part")
			node.CanCollide = false
			node.CanTouch = false
			node.CanQuery = false
			node.Anchored = true
			node.Size = Vector3.new(0.25, 0.25, (target-start).Magnitude)
			node.CFrame = CFrame.lookAt((start + target)*0.5, target)
			node.Color = Color3.fromRGB(132, 138, 180)
			node.Parent = workspace
			table.insert(buffer, node)
		end
	end
end


return true