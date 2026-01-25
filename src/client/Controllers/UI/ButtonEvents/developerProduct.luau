local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return function (player: Player, button: GuiButton)
	local passId = button:GetAttribute("passId") :: string
	EventHandler:fire("promptProductPurchase", passId)
end