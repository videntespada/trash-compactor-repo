local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

local MUSIC_MUTED_KEY = "MusicMuted"
local MUTED_IMAGE_ID = "rbxassetid://8511921026"
local UNMUTED_IMAGE_ID = "rbxassetid://8511944463"
local MUSIC_VOLUME = 0.3

local ok, svc = pcall(function()
	return game:GetService("LocalStorageService")
end)
local LocalStorageService = (ok and svc) or nil

local function applyMuteToMusic(isMuted: boolean)
	local sound = Workspace:FindFirstChild("RoundServiceSound")
	if sound and sound:IsA("Sound") then
		sound.Volume = isMuted and 0 or MUSIC_VOLUME
	end
end

return {
	init = function()
		local isMuted = false
		if LocalStorageService then
			local ok, stored = pcall(function()
				return LocalStorageService:GetItem(MUSIC_MUTED_KEY)
			end)
			if ok and stored == "true" then isMuted = true end
		end

		local icon = TopbarPlus.new()
			:setName("MusicMute")
			:setLabel("Music")
			:setImage(isMuted and MUTED_IMAGE_ID or UNMUTED_IMAGE_ID)
			:oneClick(true)
			:bindEvent("selected", function(self)
				isMuted = not isMuted
				if LocalStorageService then
					pcall(function()
						LocalStorageService:SetItem(MUSIC_MUTED_KEY, tostring(isMuted))
					end)
				end
				self:setImage(isMuted and MUTED_IMAGE_ID or UNMUTED_IMAGE_ID)
				applyMuteToMusic(isMuted)
			end)

		applyMuteToMusic(isMuted)
		task.defer(function() applyMuteToMusic(isMuted) end)

		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "RoundServiceSound" and child:IsA("Sound") then
				applyMuteToMusic(isMuted)
			end
		end)
	end,
	events = {},
}