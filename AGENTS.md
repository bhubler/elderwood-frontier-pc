# Elderwood Frontier content standards

## Match the game art in the first playable version

- Use existing Elderwood artwork and in-game scenes as visual references when creating sprites, structures, or environment pieces. Match the elevated three-quarter camera, detailed painted pixel art, muted fantasy palette, readable silhouettes, and lighting. Check scale and ground alignment beside existing characters, buildings, and terrain.
- Use the Wayfarer Inn and Stonehaven Gate as structure references, the Human and village NPCs as character references, and the village and Pinewood Wilderness Bundle setup as the reference for outdoor materials. Reuse existing materials where appropriate. Use ImageGen with project references for new original art when available.
- Integrate the styled artwork in the same update as the feature, then refine it in context. A request for a playable feature does not require a separate placeholder-art pass.
- Keep purchased third-party art local and out of the public repository.

## Ship characters with their animations and behavior

- Define what a new player character, NPC, or enemy needs to do in its first playable encounter. Create and wire the matching animations as part of that work. Cover the relevant actions, such as idle, movement, interaction, attack or cast, hit reaction, and defeat. Match the animation and behavior to the role and equipment.
- A melee bandit, for example, should already idle or patrol, notice and pursue the player, visibly wind up and swing, deal damage at contact, react to hits, and play its defeat animation. A merchant needs the movement and interaction their gameplay calls for.
- Verify new content through its normal in-game entry point. Check animation transitions and timing, silhouettes at gameplay scale, and alignment with terrain and collision. A character is ready for playtesting when its expected actions work in the game.
