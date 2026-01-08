* Project setup
 * Create round state module (phases, timers, constants, cooldown defaults)
 * Create server-side remotes for:
  * Round start/end, role assignment, timer sync
  * Trash placement preview and placement
  * Damage and ragdoll triggers
  * Ability purchase, equip, and activation
  * Push prompt and purchase flow
  * Currency, trophies, wins awarding
  * Free rewards claim checks
  * Store purchases (passes and dev products)
  * Gifting purchases and delivery
  * Events purchases and next-round application
  * Leaderboard and podium refresh hooks
 * Server-authoritative validation for all gameplay actions

* Teams, lobby, and minimum players
 * Create three teams:
  * Lobby
  * Garbage Man
  * Survivors
 * On join:
  * Spawn player into Lobby
 * Round start requirement:
  * Minimum 2 players in server to start a round

* Core round loop
 * Implement phases:
  * Intermission in Lobby
  * Active round
  * Round end results
 * Role assignment at round start:
  * Select 1 Garbage Man from Lobby using odds system
  * Assign everyone else to Survivors
 * Teleport:
  * Garbage Man to top of ramp
  * Survivors to bottom arena
 * Apply Garbage Man scaling:
  * Set character scale to 1.5x during role
  * Restore normal size at round end
 * Round timer logic:
  * Survivors win if at least one Survivor is alive when timer reaches 0
  * Garbage Man wins if all Survivors die before timer ends
 * If Garbage Man leaves during active round:
  * End the round instantly
  * Award Survivors the win
 * Round reset:
  * Teleport all players back to Lobby
  * Clear temporary round state (events, walls, cooldowns, active trash)

* Garbage Man selection odds system
 * Track per-player odds that increase each round they play without being Garbage Man
 * Use odds-weighted random selection at round start
 * On being selected as Garbage Man:
  * Reset that player’s odds
 * Monetisation modifiers:
  * 2x Garbage Man chance (store purchase)
  * Become next Garbage Man (dev product)
 * Ensure all selection logic is server-side

* Trash placement and preview system
 * Input:
  * Left click on PC
  * Tap on mobile
 * Placement rules:
  * Only Garbage Man can place
  * Only during active round
  * Only inside defined placement bounds at top of ramp
 * Placement preview:
  * Preview object follows aim position
  * Preview is transparent green when placeable
  * Preview is transparent red when:
   * Placement cooldown active
   * Out of bounds / invalid placement
 * Spawn behaviour:
  * Spawn physical trash object at valid location
  * Trash item is randomised from a defined drop pool
 * Late-round behaviour:
  * When 25 percent of the round timer remains:
   * Each drop spawns two random trash items
   * Items spawn next to each other with consistent offset
 * Cooldown:
  * Add a placement cooldown per Garbage Man
  * Ensure preview colour reflects cooldown accurately

* Trash impacts, damage, ragdoll, and pit death
 * On trash collision with a Survivor:
  * Deal 25 damage
  * Ragdoll the Survivor with knockback
  * Add short hit cooldown per victim to prevent rapid multi-hits
 * Fire pit kill zone:
  * Add kill volume in pit
  * On touch, instantly kill character
 * Ensure deaths correctly reduce Survivor alive count
* Death handling and monetised options
 * On player death:
  * Show death options UI:
   * Respawn in Lobby (free)
   * Revive (dev product)
   * Revenge on Garbage Man (dev product)
 * Respawn in Lobby:
  * Move player to Lobby team
  * Teleport to Lobby spawn
 * Revive dev product:
  * Validate round is active
  * Respawn player into arena as Survivor
 * Revenge dev product:
  * Grant temporary revenge interaction against Garbage Man
  * Keep effect simple and controlled
  * Ensure it cannot be used outside active round
 * No spectating system (players return to Lobby)

* Survivor ability system
 * Ability shop (Lobby):
  * Players purchase abilities using Cash
  * Players can equip maximum of 1 ability
 * Trophy win walls:
  * Abilities have trophy requirements for cash purchase
  * If player lacks trophies:
   * Cash purchase locked
   * Robux early unlock available
 * Ability activation (in-round, Survivors only):
  * All abilities have cooldowns
  * Server validates: team, alive, round active, cooldown
 * Implement abilities:
  * Dash: dash forward
  * Speed: temporary speed increase
  * Wall: spawn brick wall (temporary, auto-despawn)
  * Heal: heal self by 50
  * Shield: invisibility for set duration
 * Save and load:
  * Owned abilities
  * Equipped ability
  * Early unlock ownership

* Push dev product (Survivor interaction)
 * When a player is close to another player:
  * Show E prompt via radius UI
 * On E prompt:
  * Open Push dev product purchase
 * On successful purchase:
  * Ragdoll the target player
  * Launch them in a random direction with controlled force
 * Add a cooldown per purchaser to prevent spam

* Currency, trophies, and wins
 * Add and persist:
  * Cash currency
  * Trophies
  * Wins
 * Rewards:
  * Survivors win:
   * Award trophies to surviving Survivors
   * Increment wins for surviving Survivors
  * Garbage Man win:
   * Award trophies to Garbage Man
   * Increment wins for Garbage Man
  * Award cash per round (and optionally bonus on win)
 * Save after round end and after any purchase

* Free rewards system (2x trophies reward)
 * Reward:
  * Grant 2x trophies reward (define duration or permanent flag)
 * Conditions shown in UI:
  * Like the game (not tracked)
  * Favourite the game (tracked)
  * Join the group (tracked)
 * Only verify and grant based on trackable checks:
  * Favourite
  * Group membership
 * Prevent repeat claims and persist claim state

* Store and monetisation items
 * Add store items:
  * Cash currency dev product packs
  * 2x cash gamepass
  * 2x Garbage Man chance purchase
  * Shield ability purchase (Robux)
  * VIP bundle:
   * Includes 2x cash
   * Includes 2x Garbage Man chance
   * Includes Shield ability
   * Custom chat colour for VIP users
 * Ensure ownership checks are server-side
 * Apply VIP chat colour only for eligible players

* Gifting system (currency gifts)
 * Allow gifting currency to other players currently in the server
 * Flow:
  * Select recipient
  * Select gift pack
  * Gifter purchases dev product
  * On receipt, grant currency to recipient
 * Add basic rate limiting to prevent spam gifting prompts
* Events dev product page (cash and Robux)
 * Create Events page with purchases for:
  * Ice event:
   * Ramp becomes slippery during the next round
  * Fog event:
   * Vision obscured during the next round
  * Avalanche event:
   * Launch a large wave of garbage down the ramp during the next round
 * Each event purchasable with:
  * Cash
  * Robux
 * Event application:
  * Purchases apply to the next round only
  * Define a single resolution rule if multiple events bought:
   * Pick one event using a clear rule (queue, highest spend, or random)
  * Apply chosen event at round start
  * Clear event state at round end
 * Implement:
  * Ice: adjust ramp physical properties
  * Fog: apply client fog settings for round duration
  * Avalanche: spawn multiple trash items rapidly as a wave

* Leaderboard and podium display
 * Wins leaderboard:
  * Track most wins
  * Display leaderboard in Lobby
 * Podiums beside leaderboard:
  * Gold, Silver, Bronze podium platforms
  * Display top 3 players by wins:
   * Spawn their avatar rigs
   * Loop dance animations
   * Refresh periodically

* Round modifiers (replayability)
 * Add random round modifiers (one per round, low chance of happeneing):
  * Low gravity
  * Faster trash cooldown
  * Bigger trash
  * Stronger knockback
 * Apply at round start and clear at round end

* QA and edge cases
 * Multi-client testing:
  * Mobile trash placement tap
  * Placement preview colours and bounds
  * 25 percent timer double-drop behaviour
  * Push purchase and ragdoll launch direction
  * Fog visuals across clients
  * Avalanche wave performance
 * Verify round end conditions:
  * All Survivors dead ends round immediately
  * Timer end awards Survivors if at least one alive
  * Garbage Man leaving ends round instantly and awards Survivors
