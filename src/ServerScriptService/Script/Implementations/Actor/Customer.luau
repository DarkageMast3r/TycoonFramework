--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local serverScriptService = game:GetService("ServerScriptService")
local runService = game:GetService("RunService")

local contracts = serverScriptService.Script.Contracts
local common = replicatedStorage.Common
local Actor = require(common.Actor.Actor)
local Customer = require(common.Actor.Customer)
local Tr = require(common.Data.TeleoReactive)
local Position = require(common.Data.Position)
local Plot = require(common.Plot)
local Data = require(contracts.Data)


local function is_in_bounds(p: Folder?, pos: Vector3): boolean
	local p = Plot.get_by_folder(p)
	if p == nil then
		return false
	end
	return pos.X >= 0 and pos.Y >= 0 and pos.Z >= 0 and pos.X < p.size.X and pos.Z < p.size.Y
end


local programs: {Tr.program<Customer.customer>} = {
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
				if Position.distance(c.actionPosition, c.actor.position) < 0.01 then
					local price = math.random(10, 20)
					c.bill_to_pay += price
					print(`Eaten for {price}`)
					return "advanceSchedule"
				end
				return nil
			end,
			function(c)
				local p = Plot.get_by_folder(c.actor.position.plot)
				if p == nil then
					return nil
				end
				local found = Plot.asset_seek(p, "asset", "Chair")
				for _, chair in Plot.asset_seek(p, "asset", "Chair") do
					if Position.distance(chair, c.actor.position) < 5 then
						Actor.walk_to(c.actor, chair)
						c.actionPosition = chair
						return ""
					end
				end
				return "wander"
			end,
		},
		pay = {
			function(c)
				if Position.distance(c.actionPosition, c.actor.position) < 0.01 then
					local p = Plot.get_by_folder(c.actionPosition.plot)
					if p == nil then
						return nil
					end
					local player = p.owner
					if player == nil then
						return nil
					end
					local data = Data.load_data(player)
					if data == nil then
						return nil
					end
					data.currency += c.bill_to_pay
					c.bill_to_pay = 0
					
					return "advanceSchedule"
				end
				return nil
			end,
			function(c)
				local p = Plot.get_by_folder(c.actor.position.plot)
				if p == nil then
					return nil
				end
				for _, checkout in Plot.asset_seek(p, "asset", "Checkout") do
					if Position.distance(checkout, c.actor.position) < 5 then
						Actor.walk_to(c.actor, checkout)
						c.actionPosition = checkout
						return ""
					end
				end
				return "wander"
			end,
		},
		wander = {
			function(c)
				if c.schedule[1] == "wander" and c.steps_since_last_action >= 5 then
					return "advanceSchedule"
				end
				return nil
			end,
			function(c)
				local p = Plot.get_by_folder(c.actor.position.plot) :: Plot.plot
				local pos = {
					pos = c.actor.position.pos + Vector3.new(
						math.random(-1, 1),
						0,
						math.random(-1, 1)
					),
					rot = 0,
					plot = p.folder
				}
				if not is_in_bounds(pos.plot, pos.pos) then
					return ""
				end
				c.steps_since_last_action += 1
				Actor.walk_to(c.actor, pos)
				return ""
			end
		},
		advanceSchedule = {
			function(c)
				table.remove(c.schedule, 1)
				c.steps_since_last_action = 0
				c.actionPosition = {
					pos = Vector3.new(math.huge, math.huge, math.huge),
					rot = 0,
					plot = c.actionPosition.plot
				}
				return ""
			end,
		},
		exit = {
			function(c)
				if (c.actor.position.pos == Vector3.zero) then
					Customer.despawn(c)
				else
					c.steps_since_last_action = 0
					Actor.walk_to(c.actor, {
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


function Customer.spawn(pos, meshName, id)
	local actor = Actor.spawn(pos, meshName, id)
	local c: Customer.customer
	c = {
		id = actor.id,
		actor = actor,
		inventory = {},
		schedule = {"eat", "wander", "eat", "pay"},
		steps_since_last_action = 0,
		actionPosition = Position.translate(pos, -1, -1, -1, 0),
		program = Tr.program_compile(programs[1], c),
		positions_to_check = {},
		bill_to_pay = 0
	}
	c.program.object = c
	table.insert(Customer.allCustomers, c)
	return c
end


function Customer.despawn(c)
	Actor.despawn(c.actor)
end


function Customer.add_position_to_check(c, pos)
	for _, pos2 in c.positions_to_check do
		if pos2.pos == pos.pos then
			return
		end
	end
	table.insert(c.positions_to_check, pos)
end


function Customer.get_by_id(id)
	for _, c in Customer.allCustomers do
		if c.id == id then
			return c
		end
	end
	return nil
end


function Customer.get_by_actor(actor)
	for _, c in Customer.allCustomers do
		if c.actor.id == actor.id then
			return c
		end
	end
	return nil
end

function Customer.tick(dt)
	for _, c in Customer.allCustomers do
		Tr.program_step(c.program)
	end
end


function Customer.replicate(c)
	
end


return true