export type TemplateType = {
	crowns: number,
	coins: number,
	ability: string,
	lastLogin: number,
	dayStreak: number,
}
return {
	crowns = 0,
	coins = 0,
	ability = "Push",
	lastLogin = 0,
	dayStreak = 0,
} :: TemplateType
