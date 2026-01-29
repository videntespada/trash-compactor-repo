return {
	Cooldown = 5,
	init = function(player: Player)
		local character = player.Character
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		humanoid.Health += 50
	end,
}
