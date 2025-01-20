
local replicatedStorage = game:GetService("ReplicatedStorage")
local common = replicatedStorage.OTF.Common

local Program = require(common.Data.Program)

export type program<t> = {
	[string]: {
		(t) -> string?
	}
}


export type program_compiled<t> = {
	program: program<t>,
	object: t
}


local TeleoReactive = {}


function TeleoReactive.program_compile<t>(program: program<t>, object: t): Program.program<program_compiled<t>>
	if program.main == nil then
		error("Could not compile program!")
	end
	local compiled = {
		program = program,
		object = object
	}
	return Program.create(compiled, TeleoReactive.program_step)
end


function TeleoReactive.program_step<t>(program: program_compiled<t>, dt: number)
	local step = "main"
	local stepData = program.program[step]
	while typeof(stepData) ~= "function" do
		for _, func in stepData do
			local returned = func(program.object)
			if returned ~= nil then
				step = returned
				break
			end
		end
		stepData = program.program[step]
		if stepData == nil then
			return
		end
	end
	if typeof(stepData) == "function" then
		stepData(program.object)
	end
end


return TeleoReactive