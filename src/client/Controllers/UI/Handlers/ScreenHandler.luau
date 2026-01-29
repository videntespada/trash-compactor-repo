local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Value = require(ReplicatedStorage.Shared.Fusion.State.Value)
local peek = require(ReplicatedStorage.Shared.Fusion.State.peek)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	-- State
	local fusionStates: {
		[string]: {
			pos: Fusion.UsedAs<UDim2>,
			rot: Fusion.UsedAs<number>,
			visible: Fusion.UsedAs<boolean>,
		},
	} =
		{}

	for _, v in ipairs(baseUI:GetChildren()) do
		if v:HasTag("Screen") then
			local screenUI = v :: Frame

			fusionStates[screenUI.Name] = {
				pos = scope:Value(UDim2.fromScale(0.5, 0.5)),
				rot = scope:Value(0),
				visible = scope:Value(false),
			}
			local state = fusionStates[screenUI.Name]
			-- Hydrate
			scope:Hydrate(screenUI)({
				Position = scope:Spring(
					scope:Computed(function(a0, _a1)
						return a0(state.pos)
					end),
					30,
					0.8
				),
				Rotation = scope:Spring(
					scope:Computed(function(a0, _a1)
						return a0(state.rot)
					end),
					25,
					0.4
				),
				Visible = scope:Computed(function(a0, _a1)
					return a0(state.visible)
				end),
			})

			scope:Observer(state.visible):onChange(function()
				local isVisible = peek(state.visible)
				if isVisible then
					state.pos:set(UDim2.fromScale(0.5, 0.35))
					state.rot:set(math.random(-5, 5))

					task.wait()
					state.pos:set(UDim2.fromScale(0.5, 0.5))
					state.rot:set(0)
				-- task.delay(0.1, function() end)
				else
					-- ? ensures that its at its start position
					state.pos:set(UDim2.fromScale(0.5, 0.5))
					state.rot:set(0)
				end
			end)
		end
	end

	print(fusionStates)

	ClientEvents.toggleUI:Connect(function(name: string)
		if fusionStates[name] then
			local state = fusionStates[name]
			local isVisible = peek(state.visible)

			if isVisible then
				state.visible:set(false)
			else
				state.visible:set(true)
			end
		end
	end)
end
