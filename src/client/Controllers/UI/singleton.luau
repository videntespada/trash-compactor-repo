local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Shared.Fusion)

type ModuleFunctionType = (player: Player, scope: Fusion.Scope<typeof(Fusion)>, gui: PlayerGui) -> ()

return {
	init = function()
		local player = Players.LocalPlayer
		local gui = player.PlayerGui :: PlayerGui
		local scope = Fusion.scoped(Fusion) :: Fusion.Scope<typeof(Fusion)>

		local Handlers = script.Parent:WaitForChild("Handlers") :: Folder

		local required: { ModuleFunctionType } = {}

		local function collectModules(folder: Instance)
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("ModuleScript") then
					local mod = child :: ModuleScript
					local reqed = require(mod) :: ModuleFunctionType
					required[1 + #required] = reqed
				elseif child:IsA("Folder") then
					collectModules(child)
				end
			end
		end

		collectModules(Handlers)

		for _, func in ipairs(required) do
			func(player, scope, gui)
		end
	end,
	events = {},
}
