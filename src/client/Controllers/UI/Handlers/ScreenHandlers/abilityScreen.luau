local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	-- local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	-- local AbilitiesFrame = baseUI:FindFirstChild("AbilitiesFrame") :: Frame
	-- local Main = AbilitiesFrame:FindFirstChild("Main") :: Frame
	-- local Scroll = Main:FindFirstChild("CanvasGroup"):FindFirstChild("Scroll") :: ScrollingFrame

	-- EventHandler:connectClient("loadAbilitiyInventoryData", function(abilities: { string }, equippedAbility: string)
	-- 	print("Got")
	-- 	task.spawn(function()
	-- 		for _, item in ipairs(Scroll:GetChildren()) do
	-- 			if item:IsA("CanvasGroup") then
	-- 				local Frame = item:FindFirstChild("Frame") :: Frame
	-- 				local isLockedFrame = Frame:FindFirstChild("Locked") :: Frame
	-- 				local Main_2 = Frame:FindFirstChild("Main") :: Frame
	-- 				local Buttons = Main_2:FindFirstChild("Buttons") :: Frame

	-- 				local PurchaseButtons = Buttons:FindFirstChild("purchasebutton") :: Frame
	-- 				local EquipButton = Buttons:FindFirstChild("equipbutton") :: Frame
	-- 				local EquippedButton = Buttons:FindFirstChild("equippedbutton") :: Frame
	-- 				local BuyButton = PurchaseButtons:FindFirstChild("Main") :: TextButton

	-- 				-- Logic starts here
	-- 				local isOwned = table.find(abilities, item.Name) ~= nil
	-- 				local isEquipped = (item.Name == equippedAbility)

	-- 				isLockedFrame.Visible = false

	-- 				if isEquipped then
	-- 					-- State: Equipped
	-- 					EquippedButton.Visible = true
	-- 					EquipButton.Visible = false
	-- 					BuyButton.Visible = false
	-- 				elseif isOwned then
	-- 					-- State: Owned but not equipped
	-- 					EquippedButton.Visible = false
	-- 					EquipButton.Visible = true
	-- 					BuyButton.Visible = false
	-- 				else
	-- 					-- State: Not in inventory
	-- 					EquippedButton.Visible = false
	-- 					EquipButton.Visible = false
	-- 					BuyButton.Visible = true
	-- 				end
	-- 			end
	-- 		end
	-- 	end)
	-- end)
end
