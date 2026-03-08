local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return function(player: Player, button: GuiButton)
	EventHandler:fire("claimDailyReward")
end