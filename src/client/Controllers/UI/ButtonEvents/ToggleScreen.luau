local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
return function(player, from: GuiButton)
	local screenToOpen = from:GetAttribute("openScreen")
	ClientEvents.toggleUI:Fire(screenToOpen)
end
