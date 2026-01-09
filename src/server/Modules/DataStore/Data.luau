local Players = game:GetService("Players")
local ProfileStore = require(script.Parent.ProfileStore)
local Template = require(script.Parent.Template)

local PlayerStore = ProfileStore.New("_*99288f7^%237.001", Template)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function playerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function(): boolean
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Unable to load data - rejoin")
		end)
		if player.Parent == Players then
			Profiles[player] = profile
		else
			profile:EndSession()
		end
	else
		player:Kick("Unable to load data - rejoin")
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

return {
	playerAdded = playerAdded,
}
