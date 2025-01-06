--!strict
local replicatedStorage = game:GetService("ReplicatedStorage")
local contextActionService = game:GetService("ContextActionService")

local contracts = script.Parent.Parent.Contracts
local actionManager = require(contracts.ActionManager)


local actions: {[string]: (boolean) -> ()} = {}
local action_modes: {[string]: string} = {}


function actionManager.register(name, mode, callback)
	actions[name] = callback
	action_modes[name] = mode
end


local function actionHandler(action: string, state: Enum.UserInputState, input: InputObject)
	local mode = action_modes[action]
	if mode == "press" then
		actions[action](state == Enum.UserInputState.Begin)
	elseif mode == "release" then
		if state == Enum.UserInputState.End then
			actions[action](state == Enum.UserInputState.End)
		end
	end
end


function actionManager.bind(name, ...)
	contextActionService:BindAction(name, actionHandler, false, ...)
end


return true