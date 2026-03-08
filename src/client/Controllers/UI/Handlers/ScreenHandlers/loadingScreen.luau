local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")


local ClientEvents = require(StarterPlayer.StarterPlayerScripts.Client.ClientEvents)
local Fusion = require(ReplicatedStorage.Shared.Fusion)
local Spring = require(ReplicatedStorage.Shared.Fusion.Animation.Spring)
local scopePool = require(ReplicatedStorage.Shared.Fusion.Memory.scopePool)
local peek = require(ReplicatedStorage.Shared.Fusion.State.peek)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local Loading = baseUI:FindFirstChild("Loading") :: Frame
	local MainFrame = Loading:FindFirstChild("Main") :: Frame
	local Progress = MainFrame:FindFirstChild("Progressbar") :: Frame
	local ProgressBar = Progress:FindFirstChild("Progress") :: Frame

	local states = {
		visible = scope:Value(true),
		loaded = scope:Value(0),
		toLoad = {},
	}

	ClientEvents.skipLoadingScreen:Connect(function(...) 
		states.visible:set(false)
	end)

	for _, item in ipairs(workspace:GetDescendants()) do
		if item:IsA("MeshPart") or item:IsA("Decal") then
			table.insert(states.toLoad, item)
		end
	end

	for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
		table.insert(states.toLoad, item)
	end

	for _, item in ipairs(gui:GetDescendants()) do
		if item:IsA("ImageLabel") or item:IsA("ImageButton") then
			table.insert(states.toLoad, item)
		end
	end

	-- print(states.toLoad)

	scope:Observer(states.loaded):onBind(function()
		local loaded = peek(states.loaded)

		if loaded >= #states.toLoad then
			task.wait(3)
			states.visible:set(false)
		end
	end)

	scope:Hydrate(Loading)({
		Visible = scope:Computed(function(use)
			return use(states.visible)
		end),
	})

	scope:Hydrate(ProgressBar)({
		Size = scope:Spring(
			scope:Computed(function(use)
				return UDim2.fromScale(math.clamp(use(states.loaded) / #states.toLoad, 0, 1), ProgressBar.Size.Y.Scale)
			end),
			10,
			1
		),
	})

	task.wait(1)

	ContentProvider:PreloadAsync(states.toLoad, function(content: string, status: Enum.AssetFetchStatus)
		if status == Enum.AssetFetchStatus.Success then
			states.loaded:set(peek(states.loaded) + 1)
			task.wait(0.5)
		elseif status == Enum.AssetFetchStatus.Failure or status == Enum.AssetFetchStatus.TimedOut then
			warn(`Failed to load asset {content} with status {status}.`)
			task.wait(0.5)
		end
	end)
end
