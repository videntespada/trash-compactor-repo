local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local Charm = require(ReplicatedStorage.Packages.Charm)
local atom = Charm.atom
local subscribe = Charm.subscribe
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)

local function getPlayersInRound(): { Player }
	local list = Players:QueryDescendants(".InRound:not(.GarbageMan)") :: { Player }
	return list
end

local function hasEnoughPlayers(list: { Player }): boolean
	if #list < 1 then
		return true
	elseif #list >= 1 then
		return false
	else
		return false
	end
end

return function(timeLeft: number)
	local listOfPlayers = getPlayersInRound()
	local eventActive: Charm.Atom<boolean> = atom(false)

	subscribe(eventActive, function(state, _prev)
		if state then
			for _, v in ipairs(listOfPlayers) do
				EventHandler:fireClient(v, "fogEventClient", true)
			end
		else
			for _, v in ipairs(listOfPlayers) do
				EventHandler:fireClient(v, "fogEventClient", false)
			end
		end
	end)

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://103990163213954"
	sound.Volume = 3
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Once(function()
		task.wait(0.5)
		sound:Destroy()
	end)

	eventActive(true)

	for _i = timeLeft, 0, -1 do
		listOfPlayers = getPlayersInRound()
		if hasEnoughPlayers(listOfPlayers) then
			if sound then
				sound:Stop()
				eventActive(false)
			end
			break
		end
		task.wait(1)
	end

	task.wait(3)
	if sound then
		sound:Stop()
	end
	if eventActive() ~= false then
		eventActive(false)
	end
end
