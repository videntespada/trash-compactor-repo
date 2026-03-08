local SocialService = game:GetService("SocialService")

return function(player: Player, _from: GuiButton)
	local success, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)

	if success and canInvite then
		SocialService:PromptGameInvite(player)
	else
		warn("[inviteFriends] This player cannot send game invites.")
	end
end
