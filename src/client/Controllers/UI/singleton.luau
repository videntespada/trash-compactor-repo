local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Observer = require(ReplicatedStorage.Shared.Fusion.Graph.Observer)
local OnChange = require(ReplicatedStorage.Shared.Fusion.Instances.OnChange)
local OnEvent = require(ReplicatedStorage.Shared.Fusion.Instances.OnEvent)
local innerScope = require(ReplicatedStorage.Shared.Fusion.Memory.innerScope)

return {
	init = function()
		local player = Players.LocalPlayer
		local gui = player.PlayerGui
		local scope = Fusion.scoped(Fusion)

		local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
		local HUD = baseUI:FindFirstChild("HUD") :: Frame
		local TopTimerCountDownOver = HUD:FindFirstChild("TopTimerCountDownOver") :: ImageLabel
		local TimerText = TopTimerCountDownOver:FindFirstChild("TimerText") :: TextLabel

		local function toMMSS(seconds: number): string
			local minutes = math.floor(seconds / 60)
			local remainingSeconds = math.floor(seconds % 60)

			return string.format("%02d:%02d", minutes, remainingSeconds)
		end

		local states = {
			rot = scope:Value(0),
			text = scope:Value(TimerText.Text),
		}

		scope:Hydrate(TimerText)({
			Text = scope:Computed(function(use, _)
				states.rot:set(math.random(-5, 5))
				task.delay(0.1, function()
					states.rot:set(0)
				end)
				return use(states.text)
			end),
			Rotation = scope:Spring(
				scope:Computed(function(use)
					return use(states.rot)
				end),
				30,
				0.5
			),
		})

		EventHandler:connectClient("changeTimerUI", function(timeLeft: number)
			states.text:set(toMMSS(timeLeft))
		end)
	end,
	events = {},
}
