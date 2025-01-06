--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local contracts = replicatedStorage.Client.Contracts
local common = replicatedStorage.Common
local actor = require(common.Actor.Actor)
local customer = require(common.Actor.Customer)
local tr = require(common.Data.TeleoReactive)
local position = require(common.Data.Position)
local plot = require(common.Plot)


local function is_in_bounds(p: Folder?, pos: Vector3): boolean
	local p = plot.get_by_folder(p)
	if p == nil then
		return false
	end
	return pos.X >= 0 and pos.Y >= 0 and pos.Z >= 0 and pos.X < p.size.X and pos.Z < p.size.Y
end


local programs: {tr.program<customer.customer>} = {
	{
		main = {
			function(c)
				return c.actor.state ~= "idle" and "" or nil
			end,
			function(c)
				return c.schedule[1]
			end,
			function(c)
				return "exit"
			end,
		},
		eat = {
			function(c)
				if position.distance(c.actionPosition, c.actor.position) < 0.01 then
					return "advanceSchedule"
				end
				return nil
			end,
			function(c)
				local p = plot.get_by_folder(c.actor.position.plot)
				if p == nil then
					return nil
				end
				for _, chair in plot.asset_seek(p, "asset", "Chair") do
					if position.distance(chair, c.actor.position) < 5 then
						actor.walk_to(c.actor, chair)
						c.actionPosition = chair
						return ""
					end
				end
				return "wander"
			end,
		},
		wander = {
			function(c)
				if c.schedule[1] == "wander" and c.steps_since_last_action >= 15 then
					return "advanceSchedule"
				end
				return nil
			end,
			function(c)
				local p = plot.get_by_folder(c.actor.position.plot) :: plot.plot
				local pos = {
					pos = Vector3.new(
						math.random(0, p.size.X-1),
						0,
						math.random(0, p.size.Y-1)
					),
					rot = 0,
					plot = p.folder
				}
				--[[
				local pos = position.translate(
					position.translate(
						c.actor.position,
						0, 0, 0, math.random(0, 3)
					),
					1, 0, 0, 0
				)
				]]
				if not is_in_bounds(pos.plot, pos.pos) then
					return ""
				end
				c.steps_since_last_action += 1
				actor.walk_to(c.actor, pos)
				return ""
			end
		},
		advanceSchedule = {
			function(c)
				table.remove(c.schedule, 1)
				c.steps_since_last_action = 0
				return ""
			end,
		},
		exit = {
			function(c)
				if (c.actor.position.pos == Vector3.zero) then
					customer.despawn(c)
				else
					c.steps_since_last_action = 0
					actor.walk_to(c.actor, {
						pos = Vector3.zero,
						rot = 0,
						plot = c.actor.position.plot
					})
				end
				return ""
			end
		}
	}
}


function customer.spawn(pos, meshName, id)
	local actor = actor.spawn(pos, meshName, id)
	local c: customer.customer
	c = {
		id = actor.id,
		actor = actor,
		inventory = {},
		schedule = {"eat", "wander", "eat"},
		steps_since_last_action = 0,
		actionPosition = position.translate(pos, -1, -1, -1, 0),
		program = tr.program_compile(programs[1], c),
		positions_to_check = {}
	}
	c.program.object = c
	table.insert(customer.allCustomers, c)
	return c
end


function customer.despawn(c)
	actor.despawn(c.actor)
end


function customer.add_position_to_check(c, pos)
	for _, pos2 in c.positions_to_check do
		if pos2.pos == pos.pos then
			return
		end
	end
	table.insert(c.positions_to_check, pos)
end


function customer.get_by_id(id)
	for _, c in customer.allCustomers do
		if c.id == id then
			return c
		end
	end
	return nil
end


function customer.get_by_actor(actor)
	for _, c in customer.allCustomers do
		if c.actor.id == actor.id then
			return c
		end
	end
	return nil
end

function customer.tick(dt)
	for _, c in customer.allCustomers do
		tr.program_step(c.program)
	end
end


function customer.replicate(c)
	
end


return true