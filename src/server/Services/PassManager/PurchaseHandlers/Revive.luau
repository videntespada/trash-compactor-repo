local ServerScriptService = game:GetService("ServerScriptService")

local ServerEvents = require(ServerScriptService.Server.ServerEvents)
local ServerScriptService = game:GetService("ServerScriptService")
local ServerEvents = require(ServerScriptService.Server.ServerEvents)

return {
	id = "3533737864",
	init = function(player: Player)
		local canRevive = nil
		local connection

		-- Use a unique ID or just a strict timeout to prevent infinite loops
		local startTime = os.clock()

		connection = ServerEvents.canRevive:Connect(function(revivePlayer, reviveStatus)
			-- Only listen if the event is for OUR player
			if revivePlayer == player then
				canRevive = reviveStatus
			end
		end)

		ServerEvents.sendRevive:Fire(player)

		repeat
			task.wait()
		until canRevive ~= nil or (os.clock() - startTime) > 5

		if connection then
			connection:Disconnect()
		end

		return canRevive == true
	end,
}
