local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Fusion = require(ReplicatedStorage.Shared.Fusion)
local OnEvent = require(ReplicatedStorage.Shared.Fusion.Instances.OnEvent)

return function(player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui)
	local baseUI = gui:WaitForChild("ScreenGui") :: ScreenGui
	local UIFolder = script:FindFirstAncestor("UI") :: Folder
	local ButtonEvents = UIFolder:FindFirstChild("ButtonEvents") :: Folder
	local toActivate: { [string]: (player: Player, from: GuiButton, ...any) -> () } = {}

	local function onActivate(name: string, button: GuiButton)
		toActivate[name](player, button)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://88442833509532"
		sound.Parent = workspace
		sound.Ended:Once(function()
			sound:Destroy()
		end)
		sound:Play()
	end

	local function getDeviceType(): string
		if GuiService:IsTenFootInterface() then
			return "Console"
		elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
			return "Mobile"
		else
			return "PC"
		end
	end

	local function checkIfMobile(button: GuiButton)
		--* If its a mobile only button
		if button:HasTag("Mobile") then
			local platform = getDeviceType()

			-- If already mobile, leave visible
			if platform == "Mobile" then
				return
			end

			-- If not mobile, force visible = false
			if button.Name == "Main" then
				local frameParent = button.Parent :: Frame
				frameParent.Visible = false
			elseif button.Name ~= "Main" then
				button.Visible = false
			end
		end
	end

	for _, v in ipairs(ButtonEvents:GetDescendants() :: { ModuleScript }) do
		if v:IsA("ModuleScript") then
			local func = require(v) :: () -> ()

			toActivate[v.Name] = func
		end
	end

	-- print(toActivate)

	-- ! Rotation breaks background!!!
	for _, v in ipairs(baseUI:GetDescendants()) do
		if v:IsA("ImageButton") or v:IsA("TextButton") then
			local button = v

			checkIfMobile(button)

			-- If button is named "Main", then hydrate parent instead of button iself
			if button.Name == "Main" then
				local frameParent = button.Parent :: Frame
				local state = {
					size = scope:Value(frameParent.Size),
					baseSize = frameParent.Size,
					rot = scope:Value(0),
				}

				scope:Hydrate(frameParent)({
					Size = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.size)
						end),
						30,
						0.4
					),

					Rotation = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.rot)
						end),
						30,
						0.6
					),
				})

				scope:Hydrate(button)({
					-- Mouse Functionality
					[OnEvent("MouseEnter")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 1.1, state.baseSize.Y.Scale * 1.1))
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://139800881181209"
						sound.Parent = workspace
						sound.Ended:Once(function()
							sound:Destroy()
						end)
						sound:Play()
						-- state.rot:set(math.random(-5, 5))
					end,

					[OnEvent("MouseLeave")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Down")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Up")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(math.random(-5, 5))
					end,

					-- General Activated Bounce
					[OnEvent("Activated")] = function()
						if button:HasTag("ignore") then
							return
						end
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
						task.delay(0.1, function()
							state.size:set(state.baseSize)
						end)

						-- Find event to fire
						onActivate(button:GetTags()[1], button)
					end,
				})
			else
				local state = {
					size = scope:Value(button.Size),
					baseSize = button.Size,
					rot = scope:Value(0),
				}

				scope:Hydrate(button)({
					Size = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.size)
						end),
						30,
						0.4
					),

					Rotation = scope:Spring(
						scope:Computed(function(a0, a1)
							return a0(state.rot)
						end),
						30,
						0.6
					),

					-- Mouse Functionality
					[OnEvent("MouseEnter")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 1.1, state.baseSize.Y.Scale * 1.1))
						local sound = Instance.new("Sound")
						sound.SoundId = "rbxassetid://139800881181209"
						sound.Parent = workspace
						sound.Ended:Once(function()
							sound:Destroy()
						end)
						sound:Play()
						-- state.rot:set(math.random(-5, 5))
					end,

					[OnEvent("MouseLeave")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Down")] = function()
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
					end,

					[OnEvent("MouseButton1Up")] = function()
						state.size:set(state.baseSize)
						-- state.rot:set(math.random(-5, 5))
					end,

					-- General Activated Bounce
					[OnEvent("Activated")] = function()
						if button:HasTag("ignore") then
							return
						end
						state.size:set(UDim2.fromScale(state.baseSize.X.Scale * 0.9, state.baseSize.Y.Scale * 0.9))
						-- state.rot:set(0)
						task.delay(0.1, function()
							state.size:set(state.baseSize)
						end)

						-- Find event to fire
						onActivate(button:GetTags()[1], button)
					end,
				})
			end
		end
	end
end
