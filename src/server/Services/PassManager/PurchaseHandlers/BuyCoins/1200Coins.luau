local ServerScriptService = game:GetService("ServerScriptService")

local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
return {
	id = "3537816382",
	init = function(player: Player, button: GuiButton)
		local plrData = Data.grabData(player)
		local calc = plrData.coins + 1200
		Data.mutateCurrency(player, "coins", calc)
		return true
	end,
}
