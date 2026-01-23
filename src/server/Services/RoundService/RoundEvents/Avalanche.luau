local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local TrashClass = require(ServerScriptService.Server.Classes.TrashClass)
local Ignore = Workspace:WaitForChild("Ignore") :: Folder
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

local function getPlayersInRound(): boolean
	local list = Players:QueryDescendants(".InRound:not(.GarbageMan)") :: { Player }
	if #list < 1 then
		return true
	elseif #list >= 1 then
		return false
	else
		return false
	end
end

return function()
	local trashList = TrashAssets:GetChildren() :: { Model }
	for i = 1, 50 do
		-- ? Check if avalanch killed all players
		if getPlayersInRound() then
			break
		end

		-- ? Load then push
		local rndmAxis = math.random(math.rad(-360), math.rad(360))
		local currentTrash = trashList[math.random(1, #trashList)]:Clone()
		currentTrash.Parent = TrashIgnore
		currentTrash:PivotTo(randomPosOnPlaceZone() * CFrame.Angles(rndmAxis, rndmAxis, rndmAxis))
		push(currentTrash)

		-- ? Attach functionality
		local TrashObject = TrashClass.new(currentTrash, true)
		local s, e = pcall(function()
			TrashObject:CreateBounding()
		end)
		if s then
			TrashObject:StartHitbox()
		else
			warn(`[From AvalancheEvent] {e} \n\nCleaning TrashObject for {TrashObject.model}.`)
			TrashObject:Clean()
		end

		task.wait(0.3)
	end
end
