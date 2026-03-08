local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return function(player: Player, guiButton: GuiButton)
	local abilityName = guiButton:GetAttribute("abilityName") :: string
	EventHandler:fire("buyAbility", abilityName)
end