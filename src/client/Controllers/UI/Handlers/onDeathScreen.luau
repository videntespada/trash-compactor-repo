local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local peek = Fusion.peek

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local screen = baseUI:FindFirstChild("DeathScreen") :: Frame
	local skull = screen:FindFirstChild("Icon") :: ImageLabel

	local state = {
		isVisible = scope:Value(false),
		skullSize = scope:Value(skull.Size),
		skullBaseSize = skull.Size,
	}

	scope:Hydrate(skull)({
		Size = scope:Spring(
			scope:Computed(function(a0, a1)
				return a0(state.skullSize)
			end),
			30,
			0.7
		),
	})

	scope:Hydrate(screen)({
		Visible = scope:Computed(function(a0, a1)
			state.skullSize:set(UDim2.fromScale(state.skullBaseSize.X.Scale * 0.9, state.skullBaseSize.Y.Scale * 0.9))
			task.wait()
			state.skullSize:set(state.skullBaseSize)
			return a0(state.isVisible)
		end),
	})

	EventHandler:connectClient("onDeathScreen", function(toggle: boolean)
		warn(`Set to ${toggle}`)
		state.isVisible:set(toggle)
	end)
end
