local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

return function(player: Player, guiButton: GuiButton)
	ClientEvents.onDeathScreenToggle:Fire(false)
	EventHandler:fire("requestRevive")
end
