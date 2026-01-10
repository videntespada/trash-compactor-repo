local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame
	local TopFrame = HUD:FindFirstChild("Top") :: Frame
	local ContentFrame = TopFrame:FindFirstChild("Content") :: Frame
	local TimerText = ContentFrame:FindFirstChild("Timer") :: TextLabel

	local function toMMSS(seconds: number): string
		local minutes = math.floor(seconds / 60)
		local remainingSeconds = math.floor(seconds % 60)

		return string.format("%02d:%02d", minutes, remainingSeconds)
	end

	local states = {
		size = scope:Value(UDim2.fromScale(0.287, 0.55)),
		text = scope:Value(TimerText.Text),
	}

	scope:Hydrate(TimerText)({
		Text = scope:Computed(function(use, _)
			states.size:set(UDim2.fromScale(0.287, 0.6))
			task.delay(0.1, function()
				states.size:set(UDim2.fromScale(0.287, 0.55))
			end)
			return use(states.text)
		end),
		Size = scope:Spring(
			scope:Computed(function(use)
				return use(states.size)
			end),
			30,
			0.5
		),
	})

	EventHandler:connectClient("changeTimerUI", function(timeLeft: number)
		states.text:set(toMMSS(timeLeft))
	end)
end
