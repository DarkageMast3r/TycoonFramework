local GameState = {}

local gamestate_ready_callbacks = {}
GameState.is_ready = false

function GameState.on_ready(callback)
	if GameState.is_ready then
		callback()
	else
		table.insert(gamestate_ready_callbacks, callback)
	end
end

function GameState.set_ready()
	for _, callback in gamestate_ready_callbacks do
		callback()
	end
end


return GameState