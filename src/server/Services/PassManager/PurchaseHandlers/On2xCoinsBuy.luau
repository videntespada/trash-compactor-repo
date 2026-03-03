local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
return {
	id = "1713354190",
	init = function(player: Player)
		local plrData = Data.grabData(player)
		plrData.passes["2x_exp"] = true
		return true
	end,
}
