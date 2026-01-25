local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

return function(player: Player, from: GuiButton)
	-- EventHandler:fire("onClick", player, player:GetAttribute("currentPos"))
end
