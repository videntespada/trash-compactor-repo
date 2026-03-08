local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")


local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)

return function(player: Player)
	ClientEvents.skipLoadingScreen:Fire(player)
end
