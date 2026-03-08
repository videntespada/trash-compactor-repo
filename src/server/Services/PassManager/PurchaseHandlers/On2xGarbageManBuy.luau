local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)

return {
	id = "1740397153",
	init = function(player: Player)
		local plrData = Data.grabData(player)
		plrData.passes["2x_garbage_man"] = true
		return true
	end,
}
