local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local Assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
	local NotifText = Assets:WaitForChild("NotifText") :: TextLabel
	local NotifGradients = Assets:WaitForChild("NotifGradients") :: Folder
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local NotifFrame = baseUI:FindFirstChild("NotifFrame") :: Frame

	local originalNotifPos = NotifFrame.Position

	-- FIFO queue: first notifications added are shown first.
	-- Up to MAX_ACTIVE notifications can be on-screen at once;
	-- additional notifications are queued and shown as slots free up.
	type QueueEntry = { text: string, soundAssetId: number?, gradientKind: string? }
	local queue: { QueueEntry } = {}
	local activeCount = 0
	local MAX_ACTIVE = 10
	local NOTIFICATION_DURATION = 3
	local TYPEWRITER_CHAR_DELAY = 0.01

	local function playNotificationSound(soundAssetId: number?)
		if not soundAssetId or soundAssetId <= 0 then return end
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(soundAssetId)
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end

	local function processQueue()
		-- Fill available slots up to MAX_ACTIVE
		while activeCount < MAX_ACTIVE and #queue > 0 do
			local entry = table.remove(queue, 1) :: QueueEntry
			local text = entry.text
			local soundAssetId = entry.soundAssetId
			local gradientKind = entry.gradientKind
			local notif = NotifText:Clone()
			notif.Text = ""
			notif.Parent = NotifFrame

			-- Optional gradient styling
			if gradientKind then
				local template = NotifGradients:FindFirstChild(gradientKind)
				if template and template:IsA("UIGradient") then
					local gradient = template:Clone()
					gradient.Parent = notif
				end
			end

			activeCount += 1

			-- Pop-in animation for the notification container
			do
				-- Start slightly below and tween back up with a Back easing
				local startPos = UDim2.new(
					originalNotifPos.X.Scale,
					originalNotifPos.X.Offset,
					originalNotifPos.Y.Scale,
					originalNotifPos.Y.Offset + 10
				)
				NotifFrame.Position = startPos
				local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				TweenService:Create(NotifFrame, tweenInfo, { Position = originalNotifPos }):Play()
			end

			playNotificationSound(soundAssetId)

			-- Typewriter: reveal one character at a time
			task.spawn(function()
				for i = 1, #text do
					notif.Text = string.sub(text, 1, i)
					task.wait(TYPEWRITER_CHAR_DELAY)
				end
				-- After typing finishes, keep visible then destroy
				task.wait(NOTIFICATION_DURATION)
				notif:Destroy()
				activeCount -= 1
				-- Try to fill the freed slot
				processQueue()
			end)
		end
	end

	local function addNotification(text: string, soundAssetId: number?, gradientKind: string?)
		table.insert(queue, {
			text = text,
			soundAssetId = soundAssetId,
			gradientKind = gradientKind,
		})
		processQueue()
	end

	EventHandler:connectClient("sendNotification", addNotification)
	ClientEvents.sendNotification:Connect(addNotification)
end
