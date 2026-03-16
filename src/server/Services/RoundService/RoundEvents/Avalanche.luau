local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TrashClass = require(ServerScriptService.Server.Classes.TrashClass)
local Ignore = workspace:WaitForChild("Ignore") :: Folder
local TrashIgnore = Ignore:FindFirstChild("Trash") :: Folder
local Assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local TrashAssets = Assets:FindFirstChild("Trash") :: Folder
local Map = workspace:WaitForChild("Map") :: Folder
local Scriptable = Map:FindFirstChild("Scriptable") :: Folder
local PlaceZone = Scriptable:FindFirstChild("PlaceZone") :: Part

local function randomPosOnPlaceZone(): CFrame
	local r = math.random
	local randomRel = (r() * 2) - 1
	local size = PlaceZone.Size

	local offset = Vector3.new((size.X / 2) * randomRel, (size.Y / 2) + 5, (size.Z / 2) * randomRel)
	return (PlaceZone.CFrame * CFrame.new(offset))
end

local function push(m: Model)
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bv.Velocity = PlaceZone.CFrame.RightVector * -36
	bv.Parent = m.PrimaryPart
	Debris:AddItem(bv, 0.1)
end

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

local EVENT_DURATION = 15

return function()
	local listOfPlayers = getPlayersInRound()
	local trashList = TrashAssets:GetChildren() :: { Model }
	local alarmSound = Instance.new("Sound")
	alarmSound.SoundId = "rbxassetid://98726045170310"
	alarmSound.Volume = 2.5
	alarmSound.Parent = workspace
	alarmSound:Play()
	alarmSound.Ended:Once(function()
		alarmSound:Destroy()
	end)

	local rumbleSound = Instance.new("Sound")
	rumbleSound.SoundId = "rbxassetid://140593675090528"
	rumbleSound.Volume = 3
	rumbleSound.Parent = workspace
	rumbleSound:Play()
	rumbleSound.Ended:Once(function()
		rumbleSound:Destroy()
	end)

	-- Current GarbageMan gets credit for avalanche kills (environment hazard during their round).
	local function getCurrentGarbageMan(): Player?
		for _, p in ipairs(Players:GetPlayers()) do
			if p:HasTag("GarbageMan") then
				return p
			end
		end
		return nil
	end

	local gm = getCurrentGarbageMan()

	-- Run once per second for EVENT_DURATION seconds, or until no survivors left.
	for i = EVENT_DURATION, 0, -1 do
		-- ? Check if avalanch killed all players
		listOfPlayers = getPlayersInRound()
		if hasEnoughPlayers(listOfPlayers) then
			if rumbleSound then
				rumbleSound:Stop()
			end
			if alarmSound then
				alarmSound:Stop()
			end
			break
		end

		-- ? Load then push
		local rndmAxis = math.random(math.rad(-360), math.rad(360))
		local currentTrash = trashList[math.random(1, #trashList)]:Clone()
		currentTrash.Parent = TrashIgnore
		currentTrash:PivotTo(randomPosOnPlaceZone() * CFrame.Angles(rndmAxis, rndmAxis, rndmAxis))
		push(currentTrash)

		-- ? Attach functionality; kills attribute to current GarbageMan.
		local TrashObject = TrashClass.new(gm, currentTrash, false)
		local s, e = pcall(function()
			TrashObject:CreateBounding()
		end)
		if s then
			TrashObject:StartHitbox()
		else
			warn(`[From AvalancheEvent] {e} \n\nCleaning TrashObject for {TrashObject.model}.`)
			TrashObject:Clean()
		end
		task.wait(0.4)
	end
end
