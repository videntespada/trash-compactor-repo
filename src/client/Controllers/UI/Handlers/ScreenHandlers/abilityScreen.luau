local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Charm = require(ReplicatedStorage.Packages.Charm)
local SharedState = require(ReplicatedStorage.Shared.SharedState)
local atom = Charm.atom
local subscribe = Charm.subscribe

-- Order ability names by ascending price (cheapest first); abilities without cost sort last.
local function getAbilitiesSortedByPrice(): { string }
	local cost = SharedState.abilityCost or {}
	local req = SharedState.crownAbilityReq or {}
	local seen = {} :: { [string]: boolean }
	local withPrice: { { name: string, price: number } } = {}
	for name, price in pairs(cost) do
		seen[name] = true
		table.insert(withPrice, { name = name, price = price })
	end
	for name, crownReq in pairs(req) do
		if not seen[name] then
			-- Use crown req as proxy (e.g. Wall = 1e10) so it sorts last
			table.insert(withPrice, { name = name, price = crownReq })
		end
	end
	table.sort(withPrice, function(a, b)
		return a.price < b.price
	end)
	local out = {}
	for _, entry in ipairs(withPrice) do
		table.insert(out, entry.name)
	end
	return out
end

local function applyAbilityOrder(scroll: ScrollingFrame)
	local sorted = getAbilitiesSortedByPrice()
	-- Layout may be on Scroll or on a child container (e.g. Frame); support both list and grid.
	local layout = scroll:FindFirstChildOfClass("UIListLayout") or scroll:FindFirstChildOfClass("UIGridLayout")
	if not layout then
		local first = scroll:GetChildren()[1]
		if first then
			layout = first:FindFirstChildOfClass("UIListLayout") or first:FindFirstChildOfClass("UIGridLayout")
		end
	end
	if layout then
		layout.SortOrder = Enum.SortOrder.LayoutOrder
	end
	-- Tiles may be direct children of Scroll or of a child container.
	local function setOrderOnContainer(container: Instance)
		for _, child in ipairs(container:GetChildren()) do
			if not child:IsA("CanvasGroup") then
				continue
			end
			local abilityName: string? = nil
			for _, name in ipairs(sorted) do
				if child:FindFirstChild(name) then
					abilityName = name
					break
				end
			end
			local order = 999
			if abilityName then
				local idx = table.find(sorted, abilityName)
				if idx then
					order = idx
				end
			end
			child.LayoutOrder = order
		end
	end
	setOrderOnContainer(scroll)
	-- If no CanvasGroups on Scroll, try first child (e.g. content Frame).
	local scrollChildren = scroll:GetChildren()
	for _, sub in ipairs(scrollChildren) do
		if sub:IsA("Frame") or sub:IsA("Folder") then
			local hasCanvas = false
			for _, c in ipairs(sub:GetChildren()) do
				if c:IsA("CanvasGroup") then
					hasCanvas = true
					break
				end
			end
			if hasCanvas then
				setOrderOnContainer(sub)
				break
			end
		end
	end
end

-- Returns the container (Scroll or its first child) that holds the ability tile CanvasGroups.
local function getScrollTileContainer(scroll: ScrollingFrame): Instance?
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("CanvasGroup") then
			return scroll
		end
	end
	for _, sub in ipairs(scroll:GetChildren()) do
		if sub:IsA("Frame") or sub:IsA("Folder") then
			for _, c in ipairs(sub:GetChildren()) do
				if c:IsA("CanvasGroup") then
					return sub
				end
			end
		end
	end
	return scroll
end

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
			applyAbilityOrder(Scroll)
		end
	end)
	task.defer(function()
		applyAbilityOrder(Scroll)
	end)

	subscribe(abilityStates, function(state)
		local sortedNames = getAbilitiesSortedByPrice()
		local container = getScrollTileContainer(Scroll)
		for _, item in ipairs(container:GetChildren()) do
			if item:IsA("CanvasGroup") then
				local Frame: Frame?
				local abilityName: string? = nil
				for _, name in ipairs(sortedNames) do
					if item:FindFirstChild(name) then
						Frame = item:FindFirstChild(name) :: Frame
						abilityName = name
						break
					end
				end

				if not Frame or not abilityName then
					continue
				end

				local isLockedFrame = Frame:FindFirstChild("LockedFrame") :: Frame
				local amountNeeded = isLockedFrame and isLockedFrame:FindFirstChild("Trophies") :: TextLabel

				local Main_2 = Frame:FindFirstChild("Main") :: Frame
				local Buttons = Main_2:FindFirstChild("Buttons") :: Frame

				local PurchaseButtons = Buttons:FindFirstChild("purchasebutton") :: Frame
				local EquipButton = Buttons:FindFirstChild("equipbutton") :: Frame
				local EquippedButton = Buttons:FindFirstChild("equipped") :: Frame
				local BuyButton = PurchaseButtons:FindFirstChild("Main") :: TextButton

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
					if abilityName == "Wall" and amountNeeded then
						amountNeeded.Text = "GAMEPASS"
					elseif abilityName == "Bat" and amountNeeded then
						amountNeeded.Text = "7 Day Streak"
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
			task.defer(function()
				applyAbilityOrder(Scroll)
			end)

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
