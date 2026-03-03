local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local ProfileStore = require(script.Parent.ProfileStore)
local Template = require(script.Parent.Template)

local PlayerStore = ProfileStore.New("_*99288f7^%237.015", Template)
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

local function grabData(player: Player): nil | Template.TemplateType
	local profile = Profiles[player]
	if not profile then
		return nil
	end

	return profile.Data
end

local function mutateCurrency(player: Player, currency: "coins" | "crowns", to: number)
	local data = grabData(player)
	local increment = 0

	increment = to
	if data.passes["2x_coins"] then
		increment *= 2
	end

	data[currency] = increment
	EventHandler:fireClient(player, "changeCurrency", currency, increment)
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

return {
	playerAdded = playerAdded,
	grabData = grabData,
	mutateCurrency = mutateCurrency,
}
