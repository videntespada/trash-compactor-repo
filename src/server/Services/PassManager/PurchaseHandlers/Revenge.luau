local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	id = "3533738099",
	init = function(player: Player)
		local GarbageMan = CollectionService:GetTagged("GarbageMan")[1] :: Player
		local hasRun = false

		if GarbageMan == nil then
			hasRun = false
		else
			EventHandler:fireClient(GarbageMan, "fogEventClient", true)
			task.delay(10, function()
				EventHandler:fireClient(GarbageMan, "fogEventClient", false)
			end)

			-- respawn the player who bought
			EventHandler:fireClient(player, "onDeathScreen", false)
			task.spawn(function()
				player:LoadCharacterAsync()
			end)

			hasRun = true
		end

		return hasRun
	end,
}
