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

## Show public routes in the game

- Give public destinations a visible sign, door, gate, or other landmark in Elderwood's art style. Make the landmark clickable from a comfortable interaction distance, with a readable destination and a keyboard interaction. Keep intentionally hidden areas discoverable through their own clues.

## Keep outdoor regions consistent

- Use the existing Godot Wilderness Bundle tilemap for new outdoor terrain, dirt roads, and cobbled streets, and reuse its tree scenes for woodland. Keep the licensed pack local.
- Put outdoor landmarks and encounters on their regional map. Use scene changes for interiors such as crypts, and return the player to the entrance they used.

## Build and verify complete areas

- Design flooring, terrain transitions, environmental props, lighting, and boundaries together before handing off a new area. Match nearby finished areas and use the established tilesets, palette, scale, and perspective.
- Assign matching sprites to every visible character, enemy, landmark, and required interactable before marking a new area ready. Reuse existing artwork where it fits. Create and integrate matching artwork for missing pieces in the same update.
- Check the area from its normal entrance, including encounter spawns, combat, object interactions, and exits. Verify both a fresh playthrough and returning with existing progress when saved state affects the area.
- Give dismissible menus, tabs, and dialogs a clickable X in the upper-right corner. Route it through the same close behavior as the keyboard shortcut so focus, input, and state recover consistently.

## Present NPC interactions with portrait dialogue

- Use the inventory's matte charcoal panels and aged brass trim for dialogue, quest offers, quest turn-ins, and choices. Reuse the shared dialogue portrait and the common close-button behavior.
- Show the speaking NPC's in-world art in the panel, including their wardrobe variant. Use the same layout for ordinary conversation, merchants, and quest NPCs. Reserve brief HUD messages for system feedback and interactions with objects.
- Verify each new conversation through its normal interaction prompt. Check that the correct speaker appears, the dialog can be dismissed, and any quest or dialogue choices still work.
