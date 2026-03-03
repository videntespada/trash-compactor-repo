local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local peek = require(ReplicatedStorage.Shared.Fusion.State.peek)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local HUD = baseUI:FindFirstChild("HUD") :: Frame
	local BecomeGarbageManButton = HUD:FindFirstChild("BecomeGarbagemanButton") :: Frame

	local state = {
		basePos = BecomeGarbageManButton.Position,
		pos = scope:Value(BecomeGarbageManButton.Position),
		toggle = scope:Value(false),
	}

	scope:Hydrate(BecomeGarbageManButton)({
		Position = scope:Spring(
			scope:Computed(function(a0, a1)
				return a0(state.pos)
			end),
			10,
			0.5
		),

		Visible = scope:Computed(function(use)
			local currState = use(state.toggle)

			if currState then
				state.pos:set(UDim2.fromScale(0.498, 0.217))
				task.wait()
				state.pos:set(state.basePos)
			else
				state.pos:set(state.basePos)
			end

			return currState
		end),
	})

	EventHandler:connectClient("becomeGarbageManToggle", function(toggle: boolean)
		state.toggle:set(toggle)
	end)
end
