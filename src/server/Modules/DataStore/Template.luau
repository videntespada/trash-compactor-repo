export type TemplateType = {
	crowns: number,
	coins: number,
	ability: string,
	abilityInventory: { string },
	lastLogin: number,
	dayStreak: number,
	claimedReward: boolean,
	passes: {
		["2x_coins"]: boolean,
		vip: boolean,
		passAbility: boolean,
	},
}
return {
	crowns = 100,
	coins = 50,
	ability = "Wall",
	abilityInventory = {},
	lastLogin = 0,
	dayStreak = 0,
	claimedReward = false,
	passes = {
		passAbility = false,
		vip = false,
		["2x_coins"] = false,
	},
} :: TemplateType
