local Players = game:GetService("Players")

local normalProps = {
	["Material"] = Enum.Material.Plastic,
	["PhysicalProperties"] = PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1),
}

local iceProps = {
	["Material"] = Enum.Material.Ice,
	["Color"] = Color3.fromRGB(51, 88, 130),
	["PhysicalProperties"] = PhysicalProperties.new(0.7, 0.01, 0.5, 100, 1),
}

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

local function setToIce(list: { Part })
	for _, v in ipairs(list) do
		local p = v
		p.CustomPhysicalProperties = iceProps.PhysicalProperties
		p.Material = iceProps.Material
		p.Color = iceProps.Color
	end
end

local function setToNormal(list: { Part })
	for _, v in ipairs(list) do
		local p = v
		p.CustomPhysicalProperties = normalProps.PhysicalProperties
		p.Material = normalProps.Material
		if p:HasTag("middle") then
			p.Color = Color3.fromRGB(103, 108, 126)
		else
			p.Color = Color3.fromRGB(80, 84, 98)
		end
	end
end

return function(timeLeft: number)
	local listOfPlayers = getPlayersInRound()
	local Map = workspace:WaitForChild("Map") :: Folder
	local Scriptable = Map:FindFirstChild("Scriptable") :: Folder
	local RampFolder = Scriptable:FindFirstChild("RampFolder") :: Folder
	local parts = RampFolder:GetChildren()

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://86063984679312"
	sound.Volume = 3
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Once(function()
		task.wait(0.5)
		sound:Destroy()
	end)

	setToIce(parts)

	for i = timeLeft, -1, 0 do
		listOfPlayers = getPlayersInRound()
		if hasEnoughPlayers(listOfPlayers) then
			break
		end

		task.wait(1)
	end

	setToNormal(parts)
end
