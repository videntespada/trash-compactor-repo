local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
return {
	id = "3535493860",
	init = function(player: Player)
		ServerEvents.forceChooseGarbageMan:Fire(player)
		return true
	end,
}
