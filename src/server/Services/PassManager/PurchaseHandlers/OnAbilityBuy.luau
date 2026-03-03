local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Data = require(ServerScriptService.Server.Modules.DataStore.Data)
return {
	id = "1713354190",
	init = function(player: Player)
		local plrData = Data.grabData(player)
		plrData.abilityInventory[#plrData.abilityInventory + 1] = "Wall"
		-- Update client UI
		EventHandler:fireClient(player, "loadAbilitiyInventoryData", plrData.abilityInventory)
		return true
	end,
}
