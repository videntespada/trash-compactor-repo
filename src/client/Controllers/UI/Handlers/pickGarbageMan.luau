local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ThumbnailType = Enum.ThumbnailType
local ThumbnailSize = Enum.ThumbnailSize

local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local PickingGarbageman = baseUI:WaitForChild("PickingGarbageman") :: Frame

	local MovingFrame = PickingGarbageman:WaitForChild("Main"):WaitForChild("MovingFrame") :: Frame
	local PlayerImage = MovingFrame:WaitForChild("Image"):FindFirstChild("Avatar") :: ImageLabel
	local PlayerName = MovingFrame:WaitForChild("PlayerName") :: TextLabel

	local defaultAvatarSize = PlayerImage.Size
	local defaultAvatarPos = PlayerImage.Position
	local defaultNamePos = PlayerName.Position

	local raisedAvatarPos = UDim2.new(
		defaultAvatarPos.X.Scale,
		defaultAvatarPos.X.Offset,
		defaultAvatarPos.Y.Scale - 0.03,
		defaultAvatarPos.Y.Offset
	)
	local raisedNamePos = UDim2.new(
		defaultNamePos.X.Scale,
		defaultNamePos.X.Offset,
		defaultNamePos.Y.Scale - 0.03,
		defaultNamePos.Y.Offset
	)

	-- We don't use Fusion springs for movement here; movement is handled via TweenService.

	local function getRandomPlayer(): Player
		local players = Players:GetPlayers()
		local randomPlayer = players[math.random(1, #players)]
		if randomPlayer then
			return randomPlayer
		else
			return getRandomPlayer()
		end
	end

	local function getAvatarImageForPlayer(plr: Player): string?
		if not plr then
			return nil
		end
		local ok, content = pcall(function()
			local url, _ = Players:GetUserThumbnailAsync(plr.UserId, ThumbnailType.HeadShot, ThumbnailSize.Size100x100)
			return url
		end)
		if ok then
			return content
		end
		return nil
	end

	EventHandler:connectClient("displayPickingGarbageman", function(chosenPlayer: Player)
		if not chosenPlayer then
			return
		end

		-- Slightly raise avatar + name to better center them in the frame.
		PlayerImage.Position = raisedAvatarPos
		PlayerName.Position = raisedNamePos

		PickingGarbageman.Visible = true

		local duration = 3 -- ~6s picking animation
		local elapsed = 0

		local pickingSound = Instance.new("Sound")
		pickingSound.Parent = workspace
		pickingSound.SoundId = "rbxassetid://94923494962300"
		pickingSound.Volume = 0.8

		while elapsed < duration do
			local randomPlayer = getRandomPlayer()
			local thumb = getAvatarImageForPlayer(randomPlayer)
			if thumb then
				PlayerImage.Image = thumb
			end
			PlayerName.Text = randomPlayer.Name
			pickingSound:Play()
			-- Nudge the frame to create a small movement effect:
			-- snap slightly up, then tween down with Sine Out.
			MovingFrame.Position = UDim2.fromScale(0.159, 0.57)
			local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			TweenService:Create(MovingFrame, tweenInfo, { Position = UDim2.fromScale(0.159, 0.5) }):Play()

			-- Ease from fast to slow over time (simple quadratic ease-out)
			local t = elapsed / duration
			local baseWait = 0.03
			local maxExtra = 0.17 -- so wait goes from ~0.03s to ~0.2s
			local waitTime = baseWait + maxExtra * (t * t)

			task.wait(waitTime)
			elapsed += waitTime
		end

		-- Show the final chosen Garbageman
		local finalThumb = getAvatarImageForPlayer(chosenPlayer)
		if finalThumb then
			PlayerImage.Image = finalThumb
		end
		PlayerName.Text = chosenPlayer.Name
		pickingSound:Stop()
		pickingSound:Destroy()
		task.wait(2)
		-- Inform the server that this client has finished the picking animation.
		EventHandler:fire("pickingDone")
		-- Restore avatar size and positions after the selection finishes.
		PlayerImage.Size = defaultAvatarSize
		PlayerImage.Position = defaultAvatarPos
		PlayerName.Position = defaultNamePos
		PickingGarbageman.Visible = false
	end)
end