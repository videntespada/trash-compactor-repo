local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local screen = baseUI:FindFirstChild("DeathScreen") :: Frame
	local skull = screen:FindFirstChild("Icon") :: ImageLabel
	local bottomButtons = screen:FindFirstChild("BottomButtons") :: Frame

	local state = {
		isVisible = scope:Value(false),
		showBottomButtons = scope:Value(true),
		skullSize = scope:Value(skull.Size),
		skullBaseSize = skull.Size,
	}

	scope:Hydrate(skull)({
		Size = scope:Spring(
			scope:Computed(function(a0)
				return a0(state.skullSize)
			end),
			30,
			0.7
		),
	})

	scope:Hydrate(screen)({
		Visible = scope:Computed(function(a0)
			state.skullSize:set(UDim2.fromScale(state.skullBaseSize.X.Scale * 0.9, state.skullBaseSize.Y.Scale * 0.9))
			task.wait()
			state.skullSize:set(state.skullBaseSize)
			return a0(state.isVisible)
		end),
	})

	scope:Hydrate(bottomButtons)({
		Visible = scope:Computed(function(a0)
			return a0(state.isVisible) and a0(state.showBottomButtons)
		end),
	})

	local function onDeathScreen(toggle: boolean, showBottom: boolean?)
		state.isVisible:set(toggle)
		if showBottom ~= nil then
			state.showBottomButtons:set(showBottom)
		end
		if not toggle then
			state.showBottomButtons:set(true)
		end
	end

	EventHandler:connectClient("onDeathScreen", onDeathScreen)
	ClientEvents.onDeathScreenToggle:Connect(function(toggle: boolean)
		onDeathScreen(toggle, nil)
	end)
end
