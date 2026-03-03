local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(result: Enum.AvatarPromptResult)
			if result == Enum.AvatarPromptResult.Success then
				EventHandler:fire("toggleFavorited", true)
			elseif result == Enum.AvatarPromptResult.Failed then
				warn("Failed to recieve result, or already favorited")
				EventHandler:fire("toggleFavorited", true)
			elseif result == Enum.AvatarPromptResult.PermissionDenied then
				warn("Denied permission to recieve result")
				EventHandler:fire("toggleFavorited", false)
			end
		end)

		EventHandler:connectClient("promptFavorite", function()
			AvatarEditorService:PromptSetFavorite(81550249001229, Enum.AvatarItemType.Asset, true)
		end)

		EventHandler:connectClient("promptJoinGroup", function()
			local player = game.Players.LocalPlayer
			if player:IsInGroupAsync(99043239) then
				EventHandler:fire("toggleJoinedGroup", true)
				return
			end

			local s, result = GroupService:PromptJoinAsync(99043239)

			if not s then
				warn("Error with prompting")
				return
			end

			if result == Enum.GroupMembershipStatus.Joined or result == Enum.GroupMembershipStatus.AlreadyMember then
				EventHandler:fire("toggleJoinedGroup", true)
			elseif result == Enum.GroupMembershipStatus.None then
				EventHandler:fire("toggleJoinedGroup", false)
			end
		end)
	end,
	events = {},
}
