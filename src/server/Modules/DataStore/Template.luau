export type TemplateType = {
	crowns: number,
	coins: number,
	ability: string,
	abilityInventory: { string },
	lastLogin: number,
	dayStreak: number,
	claimedReward: boolean,
	todayClaimed: boolean,
	passes: {
		["2x_coins"]: boolean,
		["2x_garbage_man"]: boolean,
		vip: boolean,
		passAbility: boolean,
	},
}
return {
	crowns = 0,
	coins = 50,
	ability = "",
	abilityInventory = {},
	lastLogin = 0,
	dayStreak = 0,
	claimedReward = false,
	passes = {
		passAbility = false,
		vip = false,
		["2x_coins"] = false,
		["2x_garbage_man"] = false,
	},
} :: TemplateType
