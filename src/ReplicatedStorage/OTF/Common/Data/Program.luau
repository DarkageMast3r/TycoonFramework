export type program<t> = {
	program: t,
	step: (t, dt: number) -> ()
}


local Program = {}


function Program.create<t>(program: t, step: (t, number) -> ())
	return {
		program = program,
		step = step
	}
end


function Program.step<t>(program: program<t>, dt: number)
	program.step(program.program, dt)
end


return Program