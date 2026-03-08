local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local EventHandler = require(ReplicatedStorage.Shared.EventHandler)
local Fusion = require(ReplicatedStorage.Shared.Fusion)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local Assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
	local NotifText = Assets:WaitForChild("NotifText") :: TextLabel
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local NotifFrame = baseUI:FindFirstChild("NotifFrame") :: Frame

	-- FIFO queue: first notification added is first shown
	local queue: { string } = {}
	local isShowing = false
	local NOTIFICATION_DURATION = 3
	local TYPEWRITER_CHAR_DELAY = 0.01

	local function processQueue()
		if isShowing or #queue == 0 then
			return
		end
		-- Show the first in queue (FIFO)
		local text = table.remove(queue, 1)
		isShowing = true
		local notif = NotifText:Clone()
		notif.Text = ""
		notif.Parent = NotifFrame

		-- Typewriter: reveal one character at a time
		task.spawn(function()
			for i = 1, #text do
				notif.Text = string.sub(text, 1, i)
				task.wait(TYPEWRITER_CHAR_DELAY)
			end
			-- After typing finishes, keep visible then destroy
			task.wait(NOTIFICATION_DURATION)
			notif:Destroy()
			isShowing = false
			processQueue()
		end)
	end

	local function addNotification(text: string)
		table.insert(queue, text)
		processQueue()
	end

	EventHandler:connectClient("sendNotification", addNotification)
	ClientEvents.sendNotification:Connect(addNotification)
end
