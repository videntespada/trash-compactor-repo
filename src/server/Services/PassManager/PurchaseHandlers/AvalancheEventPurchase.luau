local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
return {
	id = "3521205715",
	init = function()
		ServerEvents.sendRoundEvent:Fire("Avalanche")
		return true
	end,
}
