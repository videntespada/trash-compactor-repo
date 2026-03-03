local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
return {
	init = function()
		local atmosphere = Lighting:FindFirstChild("Atmosphere") :: Atmosphere
		local originalEnd = Lighting.FogEnd
		local originalStart = Lighting.FogStart
		local originalColor = Lighting.FogColor
		local originalOutdoorAmbient = Lighting.OutdoorAmbient

		EventHandler:connectClient("fogEventClient", function(toggle: boolean)
			if toggle then
				atmosphere.Parent = workspace

				local fogInInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
				local fogInGoals = {
					FogEnd = 30,
					FogStart = 0,
					FogColor = Color3.fromRGB(80, 80, 80),
					OutdoorAmbient = Color3.fromRGB(50, 50, 50),
				}

				local tweenIn = TweenService:Create(Lighting, fogInInfo, fogInGoals)

				tweenIn:Play()
			else
				local fogOutInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
				local fogOutGoals = {
					FogEnd = originalEnd,
					FogStart = originalStart,
					FogColor = originalColor,
					OutdoorAmbient = originalOutdoorAmbient,
				}

				local tweenOut = TweenService:Create(Lighting, fogOutInfo, fogOutGoals)
				tweenOut:Play()
				task.wait(3)
				atmosphere.Parent = Lighting
			end
		end)
	end,
	events = {},
}
