local gamestate = {}

local gamestate_ready_callbacks = {}
gamestate.is_ready = false

function gamestate.on_ready(callback)
	if gamestate.is_ready then
		callback()
	else
		table.insert(gamestate_ready_callbacks, callback)
	end
end

function gamestate.set_ready()
	for _, callback in gamestate_ready_callbacks do
		callback()
	end
end


return gamestate