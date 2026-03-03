local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TopbarPlus = require(ReplicatedStorage.Packages.TopbarPlus)

return {
	init = function()
		local icon = TopbarPlus.new()
		
		icon:setImage(8511921026)
	end,
	events = {},
}