local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local peek = require(ReplicatedStorage.Shared.Fusion.State.peek)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame
	local Bottom = HUD:FindFirstChild("Bottom") :: Frame

	local CoinsFrame = Bottom:FindFirstChild("Coins") :: Frame
	local CrownsFrame = Bottom:FindFirstChild("Trophy") :: Frame
	local CoinsText = CoinsFrame:FindFirstChild("Main"):FindFirstChild("Title") :: TextLabel
	local CrownsText = CrownsFrame:FindFirstChild("Main"):FindFirstChild("Title") :: TextLabel

	local state = {
		coinsAmount = scope:Value(0),
		crownsAmount = scope:Value(0),
	}

	local animatedCoins =
		scope:Tween(state.coinsAmount, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

	scope:Hydrate(CoinsText)({
		Text = scope:Computed(function(use)
			local newAmount = use(animatedCoins)
			local roundedAmount = math.round(newAmount)
			return tostring(roundedAmount)
		end),
	})

	local animatedCrowns =
		scope:Tween(state.crownsAmount, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))

	scope:Hydrate(CrownsText)({
		Text = scope:Computed(function(use)
			local newAmount = use(animatedCrowns)
			local roundedAmount = math.round(newAmount)
			return tostring(roundedAmount)
		end),
	})

	EventHandler:connectClient("changeCurrency", function(which: "coins" | "crowns", to: number)
		if which == "coins" then
			state.coinsAmount:set(to)
		elseif which == "crowns" then
			state.crownsAmount:set(to)
		end
	end)
end
