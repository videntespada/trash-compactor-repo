local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
return function (character: Model, hrp: BasePart)
	local assets = ReplicatedStorage:WaitForChild("Assets")
	local ignoreFolder = workspace:FindFirstChild("Ignore")

	local eff = assets:FindFirstChild("Purchase"):Clone() :: Part
	eff.CFrame = hrp.CFrame
	eff.Parent = ignoreFolder

	local purchaseSound = Instance.new("Sound")
	purchaseSound.Parent = workspace
	purchaseSound.Volume = 2
	purchaseSound.SoundId = "rbxassetid://90253331991656"
	purchaseSound.Ended:Once(function(soundId)
		purchaseSound:Destroy()
	end)
	purchaseSound:Play()

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = eff
	weld.Parent = eff

	for _, effect in ipairs(eff:GetDescendants()) do
		if effect:IsA("ParticleEmitter") then
			local count = effect:GetAttribute("EmitCount") or 10
			effect:Emit(count)
		end
	end

	Debris:AddItem(eff, 5)
end