local TweenService = game:GetService("TweenService")

local function smoothScroll(frame: ScrollingFrame, targetY: number)
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(frame, info, {
		CanvasPosition = Vector2.new(0, targetY),
	})

	tween:Play()
end

return function(player: Player, GuiButton: GuiButton)
	local ShopFrame = GuiButton:FindFirstAncestor("ShopFrame") :: Frame
	local MainShopFrame = ShopFrame:FindFirstChild("Main") :: Frame
	local Scroll = MainShopFrame:FindFirstChild("CanvasGroup"):FindFirstChild("Scroll") :: ScrollingFrame

	local to = GuiButton:GetAttribute("to")

	if to == "top" then
		smoothScroll(Scroll, 0)
	else
		smoothScroll(Scroll, Scroll.AbsoluteCanvasSize.Y)
	end
end
