local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame
	local Top = HUD:FindFirstChild("Top") :: Frame
	local Content = Top:FindFirstChild("Content") :: Frame

	local PlayerAmountText = Content:FindFirstChild("PlayerAmount") :: TextLabel

	local states = {
		text = scope:Value("0"),
		size = scope:Value(PlayerAmountText.Size),
	}

	scope:Hydrate(PlayerAmountText)({
		Text = scope:Computed(function(a0, a1)
			states.size:set(UDim2.fromScale(0.097, 0.675))
			task.delay(0.1, function()
				states.size:set(UDim2.fromScale(0.095, 0.55))
			end)
			return a0(states.text)
		end),
	})

	EventHandler:connectClient("changePlayerCount", function(to: number)
		states.text:set(tostring(to))
	end)
end
