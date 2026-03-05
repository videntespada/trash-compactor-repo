local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

local MUTED_IMAGE_ID = 8511921026
local UNMUTED_IMAGE_ID = 8511944463
local MUSIC_VOLUME = 0.3

local function applyMuteToMusic(isMuted: boolean)
	local sound = Workspace:FindFirstChild("RoundServiceSound")
	if sound and sound:IsA("Sound") then
		sound.Volume = isMuted and 0 or MUSIC_VOLUME
	end
end

return {
	init = function()
		local isMuted = false

		local icon = TopbarPlus.new()
			:setImage(UNMUTED_IMAGE_ID, "Deselected")
			:setImage(MUTED_IMAGE_ID, "Selected")
			:setLabel("Music", "Deselected")
			:setLabel("Muted", "Selected")

		-- Apply current mute state to any existing music
		applyMuteToMusic(isMuted)

		-- When round music is created, apply current mute state
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "RoundServiceSound" and child:IsA("Sound") then
				child.Volume = isMuted and 0 or MUSIC_VOLUME
			end
		end)

		-- Icon is selected = muted, deselected = unmuted; sync mute state when user toggles
		icon.selected:Connect(function()
			isMuted = true
			applyMuteToMusic(true)
		end)
		icon.deselected:Connect(function()
			isMuted = false
			applyMuteToMusic(false)
		end)
	end,
	events = {},
}