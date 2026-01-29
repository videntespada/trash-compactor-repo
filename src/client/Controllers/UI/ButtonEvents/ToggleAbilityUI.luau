local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
return function(player: Player, from: GuiButton)
	ClientEvents.toggleUI:Fire("AbilitiesFrame")
end
