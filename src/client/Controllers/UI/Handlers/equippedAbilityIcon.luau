local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local atom = require(ReplicatedStorage.Packages.Charm).atom
local subscribe = require(ReplicatedStorage.Packages.Charm).subscribe
local SharedState = require(ReplicatedStorage.Shared.SharedState)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local ImagePerKeycode = require(ReplicatedStorage.Shared.ImagePerKeycode)

local THROW_ICON = "rbxassetid://81594873056134"

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local Ability = baseUI:WaitForChild("Ability") :: Frame

	local EnabledAbility = Ability:WaitForChild("Enabled") :: ImageLabel
	local DisabledAbility = Ability:WaitForChild("Disabled") :: ImageLabel

	local InputGlyph = Ability:WaitForChild("InputGlyph") :: ImageLabel

	local ability = atom("")
	local isOnCooldown = false
	local isInRound = false
	local isGarbageMan = false
	local currentImageId: string? = nil
	local cooldownToken: any = nil

	local function updateAbilityVisibility()
		-- Lobby/intermission: hide the entire Ability frame. In round: show only if GM (throw) or survivor with an ability equipped.
		Ability.Visible = isInRound and (isGarbageMan or currentImageId ~= nil)
	end

	local function getEnabledIcon(): ImageLabel?
		return EnabledAbility:FindFirstChild("Main") and EnabledAbility.Main:FindFirstChild("AbilityIcon") :: ImageLabel or nil
	end
	local function getDisabledIcon(): ImageLabel?
		return DisabledAbility:FindFirstChild("Main") and DisabledAbility.Main:FindFirstChild("AbilityIcon") :: ImageLabel or nil
	end

	-- Set which image is shown: throw icon when Garbageman, equipped ability otherwise. Only toggle Enabled/Disabled when in round.
	local function updateAbilityIcon()
		local imageId = if isGarbageMan then THROW_ICON else (currentImageId or "")
		local enabledIcon = getEnabledIcon()
		local disabledIcon = getDisabledIcon()
		if enabledIcon then
			enabledIcon.Image = imageId
		end
		if disabledIcon then
			disabledIcon.Image = imageId
		end
		-- Only set Enabled/Disabled visibility when in round (Ability frame is visible).
		if not isInRound then
			return
		end
		-- GM: show Disabled during throw cooldown, Enabled otherwise. Survivor: show Disabled during ability cooldown, Enabled otherwise.
		if isGarbageMan then
			EnabledAbility.Visible = not isOnCooldown
			DisabledAbility.Visible = isOnCooldown
		elseif currentImageId then
			EnabledAbility.Visible = not isOnCooldown
			DisabledAbility.Visible = isOnCooldown
		else
			EnabledAbility.Visible = false
			DisabledAbility.Visible = false
		end
	end

	local function updateInputGlyph(inputType: InputObject)
		local isTouch = inputType.UserInputType == Enum.UserInputType.Touch
		InputGlyph.Visible = not isTouch
		if not isTouch then
			InputGlyph.Image = ImagePerKeycode[Enum.KeyCode.E]
		end
	end

	UserInputService.InputChanged:Connect(updateInputGlyph)

	updateAbilityVisibility()

	-- React to changes in the equipped ability by updating stored image and icon
	subscribe(ability, function(newAbility)
		if newAbility == "" then
			currentImageId = nil
		else
			currentImageId = SharedState.abilityImages[newAbility]
		end
		updateAbilityVisibility()
		updateAbilityIcon()
	end)

	-- Keep the atom in sync with the server-equipped ability
	EventHandler:connectClient(
		"loadAbilitiyInventoryData",
		function(_abilities: { string }, equippedAbility: string, _crowns: number?)
			ability(equippedAbility or "")
		end
	)

	-- Track whether the local player is currently counted as "InRound" on the server.
	EventHandler:connectClient("abilityInRound", function(inRound: boolean)
		isInRound = inRound
		updateAbilityVisibility()
		if isInRound then
			updateAbilityIcon()
		end
	end)

	-- Track whether the local player is currently the GarbageMan; icon shows throw image when true.
	EventHandler:connectClient("toggleGarbageVisualization", function(toggle: boolean)
		isGarbageMan = toggle
		updateAbilityVisibility()
		if isInRound then
			updateAbilityIcon()
		end
	end)

	-- Ability cooldown (survivors): show Disabled for duration then Enabled.
	EventHandler:connectClient("abilityCooldown", function(duration: number)
		if isGarbageMan then
			return
		end
		if not currentImageId then
			return
		end

		isOnCooldown = true
		updateAbilityIcon()

		local myToken = {}
		cooldownToken = myToken

		task.delay(duration, function()
			if cooldownToken ~= myToken then
				return
			end
			isOnCooldown = false
			updateAbilityIcon()
		end)
	end)

	-- Throw cooldown (Garbageman): show Disabled for duration then Enabled.
	EventHandler:connectClient("throwCooldown", function(duration: number)
		if not isGarbageMan then
			return
		end

		isOnCooldown = true
		updateAbilityIcon()

		local myToken = {}
		cooldownToken = myToken

		task.delay(duration, function()
			if cooldownToken ~= myToken then
				return
			end
			isOnCooldown = false
			updateAbilityIcon()
		end)
	end)
end
