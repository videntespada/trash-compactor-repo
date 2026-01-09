local Players = game:GetService("Players")

local types = require(script.Parent.types)

local state: types.RoundStates = "Lobby"
local lobbyTime = 10
local intermissionTime = 6
local roundLength = 30

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

return {
	init = function()
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
					-- Countdown before round starts
					task.wait(1)
					print(`${lobbyTime - i} seconds left until round starts..`)
				end

				transferPlayersToRound()
				state = "InRound"
				continue
			end

			if state == "Intermission" then
				for i = 1, intermissionTime do
					-- Show stats, small intermission
					task.wait(1)
					print(`${intermissionTime - i} seconds left for intermission..`)
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
					-- ! Show player states every second just as debug
					local players = getPlayerInRound()
					for _, player in ipairs(players) do
						local plrStats = playerStats[player]
						print(plrStats)
					end
					print(`${roundLength - i} seconds left for round`)
					task.wait(1)
				end
			end
		end
	end,
	events = {},
}
