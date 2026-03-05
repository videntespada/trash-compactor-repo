local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Charm = require(ReplicatedStorage.Packages.Charm)
local SharedState = require(ReplicatedStorage.Shared.SharedState)
local atom = Charm.atom
local subscribe = Charm.subscribe

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local AbilitiesFrame = baseUI:FindFirstChild("AbilitiesFrame") :: Frame
	local Main = AbilitiesFrame:FindFirstChild("Main") :: Frame
	local Scroll = Main:FindFirstChild("CanvasGroup"):FindFirstChild("Scroll") :: ScrollingFrame

	local abilityStates = atom({} :: { [string]: "equipped" | "owned" | "locked" })
	local currentCrowns = 0

	AbilitiesFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if AbilitiesFrame.Visible then
			EventHandler:fire("requestAbilityInventory")
		end
	end)

	subscribe(abilityStates, function(state)
		for _, item in ipairs(Scroll:GetChildren()) do
			if item:IsA("CanvasGroup") then
				local Frame: Frame?

				for key, _ in state do
					if item:FindFirstChild(key) then
						Frame = item:FindFirstChild(key) :: Frame
						-- warn(`Ability ${key} found in item ${item.Name}`)
						break
					else
						-- print(`Ability ${key} not found in item ${item.Name}`)
						Frame = nil
						continue
					end
				end

				if not Frame then
					-- warn(`Ability not found in item ${item.Name}`)
					continue
				end

				local isLockedFrame = Frame:FindFirstChild("LockedFrame") :: Frame
				local amountNeeded = isLockedFrame:FindFirstChild("Trophies") :: TextLabel

				local Main_2 = Frame:FindFirstChild("Main") :: Frame
				local Buttons = Main_2:FindFirstChild("Buttons") :: Frame

				local PurchaseButtons = Buttons:FindFirstChild("purchasebutton") :: Frame
				local EquipButton = Buttons:FindFirstChild("equipbutton") :: Frame
				local EquippedButton = Buttons:FindFirstChild("equipped") :: Frame
				local BuyButton = PurchaseButtons:FindFirstChild("Main") :: TextButton

				local abilityName = Frame.Name
				local tileState = state[abilityName] or "locked"

				if tileState == "equipped" then
					EquippedButton.Visible = true
					EquipButton.Visible = false
					BuyButton.Visible = false
					if isLockedFrame then
						isLockedFrame.Visible = false
					end
				elseif tileState == "owned" then
					EquippedButton.Visible = false
					EquipButton.Visible = true
					BuyButton.Visible = false
					if isLockedFrame then
						isLockedFrame.Visible = false
					end
				else
					EquippedButton.Visible = false
					EquipButton.Visible = false
					BuyButton.Visible = true

					-- Locked: show how many trophies are needed if they don't meet the crown requirement
					local reqTable = SharedState.crownAbilityReq
					local required = reqTable and reqTable[abilityName]
					if required and currentCrowns < required then
						local diff = required - currentCrowns
						if amountNeeded then
							amountNeeded.Text = string.format("%d Trophies", diff)
						end
						if isLockedFrame then
							isLockedFrame.Visible = true
						end
					else
						if isLockedFrame then
							isLockedFrame.Visible = false
						end
					end
					if abilityName == "Wall" then
						amountNeeded.Text = "GAMEPASS"
					end
				end
			end
		end
	end)

	EventHandler:connectClient(
		"loadAbilitiyInventoryData",
		function(abilities: { string }, equippedAbility: string, crowns: number?)
			if crowns ~= nil then
				currentCrowns = crowns
			end

			abilityStates(function(prev)
				local new: { [string]: "equipped" | "owned" | "locked" } = {}

				for _, name in ipairs(abilities) do
					if name == equippedAbility then
						new[name] = "equipped"
					else
						new[name] = "owned"
					end
				end

				if equippedAbility ~= "" and not new[equippedAbility] then
					new[equippedAbility] = "equipped"
				end

				return new
			end)
		end
	)
end
