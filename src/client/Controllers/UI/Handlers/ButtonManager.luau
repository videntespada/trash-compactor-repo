local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Spring = require(ReplicatedStorage.Shared.Fusion.Animation.Spring)
local OnEvent = require(ReplicatedStorage.Shared.Fusion.Instances.OnEvent)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame

	-- ! Rotation breaks background!!!
	for _, v in ipairs(HUD:GetDescendants()) do
		if v:IsA("ImageButton") or v:IsA("TextButton") then
			local button = v

			-- If button is named "Main", then hydrate parent instead of button iself
			if button.Name == "Main" then
				local frameParent = button.Parent :: Frame
				local state = {
					size = scope:Value(frameParent.Size),
					baseSize = frameParent.Size,
					rot = scope:Value(0),
				}

				scope:Hydrate(frameParent)({
					Size = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.size)
						end),
						30,
						0.4
					),

					Rotation = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.rot)
						end),
						30,
						0.6
					),
				})

				scope:Hydrate(button)({
					-- Mouse Functionality
					[OnEvent("MouseEnter")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 1.1, state.baseSize.Y.Scale * 1.1))
						-- state.rot:set(math.random(-5, 5))
					end,

					[OnEvent("MouseLeave")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Down")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Up")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(math.random(-5, 5))
					end,

					-- General Activated Bounce
					[OnEvent("Activated")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
						task.delay(0.1, function()
							state.size:set(state.baseSize)
						end)
					end,
				})
			else
				local state = {
					size = scope:Value(button.Size),
					baseSize = button.Size,
					rot = scope:Value(0),
				}

				scope:Hydrate(button)({
					Size = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.size)
						end),
						30,
						0.4
					),

					Rotation = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.rot)
						end),
						30,
						0.6
					),

					-- Mouse Functionality
					[OnEvent("MouseEnter")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 1.1, state.baseSize.Y.Scale * 1.1))
						-- state.rot:set(math.random(-5, 5))
					end,

					[OnEvent("MouseLeave")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Down")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Up")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(math.random(-5, 5))
					end,

					-- General Activated Bounce
					[OnEvent("Activated")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
						task.delay(0.1, function()
							state.size:set(state.baseSize)
						end)
					end,
				})
			end
		end
	end
end
