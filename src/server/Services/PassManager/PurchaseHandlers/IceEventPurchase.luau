local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
return {
	id = "3521203938",
	init = function()
		ServerEvents.sendRoundEvent:Fire("Ice")
		return true
	end,
}
