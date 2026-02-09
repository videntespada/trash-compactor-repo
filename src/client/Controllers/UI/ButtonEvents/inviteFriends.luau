local SocialService = game:GetService("SocialService")
return function(player, from: GuiButton)
	local s, canInvite = pcall(function()
		return SocialService:CanSendCallInviteAsync(player)
	end)

	if s and canInvite then
		SocialService:PromptGameInvite(player)
	else
		warn("[SocialService from inviteFriends.luau] This player cannot send invites")
	end
end
