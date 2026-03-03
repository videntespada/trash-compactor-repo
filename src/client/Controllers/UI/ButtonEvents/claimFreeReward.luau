local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return function(player: Player, gui: GuiButton)
	EventHandler:fire("checkRewardStatus")
end
