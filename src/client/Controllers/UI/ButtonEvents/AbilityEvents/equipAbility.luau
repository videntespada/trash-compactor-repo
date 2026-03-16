local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local isInRound = false
EventHandler:connectClient("abilityInRound", function(inRound: boolean)
	isInRound = inRound
end)

return function(player: Player, guiButton: GuiButton)
	if isInRound then
		return
	end
	local abilityName = guiButton:GetAttribute("abilityName") :: string
	EventHandler:fire("equipAbility", abilityName)
end