local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local function checkUserVip(player: Player): boolean
	return player:GetAttribute("IsVIP") == true
end

return {
	init = function()
		task.defer(function()
			TextChatService.OnIncomingMessage = function(message: TextChatMessage)
				if not message.TextSource then
					return nil
				end

				local player = Players:GetPlayerByUserId(message.TextSource.UserId)
				if not player then
					return nil
				end

				if player.UserId == 8119156 then
					local properties = Instance.new("TextChatMessageProperties")

					-- Initial's tag
					local tag = `<b><font color='#5D3FD3'>[THE GOAT]</font></b>`

					properties.PrefixText = `{tag}`

					return properties
				end

				if checkUserVip(player) then
					local properties = Instance.new("TextChatMessageProperties")

					-- VIP Tag + Gold Name
					local tag = `<b><font color='#FFD700'>[VIP]</font></b>`
					local goldName = `<font color='#FFD700'>{message.PrefixText}</font>`

					properties.PrefixText = `{tag} {goldName}`

					return properties
				end

				return nil
			end
		end)
	end,
	events = {},
}
