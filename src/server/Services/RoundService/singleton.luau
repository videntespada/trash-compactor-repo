local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local types = require(script.Parent.types)

local state: types.RoundStates = "Lobby"
local lobbyTime = 60
local intermissionTime = 15
local roundLength = 120

local playerStats: { [Player]: {
	kills: number,
	cash: number,
} } = {}

local function checkForPlayers(): boolean
	local enoughPlayers = #Players:GetPlayers() >= 1

	if not enoughPlayers then
		local totalPlayers = #Players:GetPlayers()
		warn(`Need ${1 - totalPlayers} more players to start.`)
		return false
	else
		return true
	end
end

local function getPlayerInRound(): { Player }
	local t = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if not player:HasTag("InRound") then
			continue
		end
		t[1 + #t] = player
	end

	return t
end

local function transferPlayersToRound()
	for _, player in Players:GetPlayers() do
		if player:HasTag("AFK") then
			continue
		end
		player:AddTag("InRound")

		playerStats[player] = {
			cash = 0,
			kills = 0,
		}
		print(`Added ${player.Name} to round.`)
	end
end

local function changePlayerCount(tag: string)
	if tag == "InRound" then
		local amountCount = #CollectionService:GetTagged(tag)
		EventHandler:broadcast("changePlayerCount", amountCount)
	end
end

return {
	init = function()
		local _onRemoved = CollectionService.TagRemoved:Connect(changePlayerCount)
		local _onAdd = CollectionService.TagAdded:Connect(changePlayerCount)

		-- Own loop, since rounds continue indefinitely
		while true do
			if state == "Lobby" then
				-- Re-wait until enough players
				if not checkForPlayers() then
					task.wait(4)
					continue
				end
				warn("We have enough players, starting")

				for i = 1, lobbyTime do
					local timeLeft = lobbyTime - i
					-- Countdown before round starts
					-- print(`${timeLeft} seconds left until round starts..`)
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end

				transferPlayersToRound()
				state = "InRound"
				continue
			end

			if state == "Intermission" then
				for i = 1, intermissionTime do
					local timeLeft = intermissionTime - i
					-- Show stats, small intermission
					-- print(`${timeLeft} seconds left for intermission..`)
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end
				state = "Lobby"
				continue
			end

			if state == "InRound" then
				-- Round end
				task.delay(roundLength, function()
					local players = getPlayerInRound()
					for _, player in ipairs(players) do
						local plrStats = playerStats[player]

						-- plrStats.cash whatever
						player:RemoveTag("InRound")
					end
					table.clear(playerStats)

					state = "Intermission"
				end)

				-- Actual countdown
				for i = 1, roundLength do
					local timeLeft = roundLength - i
					-- ! Show player states every second just as debug
					local players = getPlayerInRound()
					for _, player in ipairs(players) do
						local plrStats = playerStats[player]
						print(plrStats)
					end
					-- print(`${timeLeft} seconds left for round`)
					EventHandler:broadcast("changeTimerUI", timeLeft)
					task.wait(1)
				end
			end
		end
	end,
	events = {
		"changeTimerUI",
		"changePlayerCount",
	},
}
