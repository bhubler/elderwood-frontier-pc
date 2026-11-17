# Elderwood Frontier — PC Edition

Personal dark-fantasy isometric RPG, built in **Godot 4** using **GDScript**.

## Version 0.1 — movement and terrain foundation

This is a **first playable technical prototype**, not the final art direction.

- Procedurally drawn isometric diamond terrain with paths
- Decorative trees, rocks, and plants
- Player avatar with WASD / arrow-key movement
- Following camera
- No external assets or plugins required

**Not implemented yet:** collisions with trees, inventory, NPCs, combat, saving, detailed sprite artwork, lighting, or quests. Those are future milestones.

## Open on Windows

1. Install the **standard** Godot 4 editor (not the .NET edition).
2. Clone this repository using GitHub Desktop.
3. In Godot Project Manager choose **Import** and select the repository's `project.godot`.
4. Open the project and press **F5** to play.
5. Move with **WASD** or the arrow keys.

## Architecture

- `scenes/world.tscn` — main scene
- `scenes/player.tscn` — player and camera
- `scripts/world.gd` — prototype isometric terrain and props
- `scripts/player.gd` — keyboard movement and placeholder character

The original browser prototype lives in a **different repository**. This is a clean rebuild, not a conversion of browser saves.

## Development principles

Preserve working milestones, keep scripts modular, and validate in the Godot editor before expanding. Add art and game systems incrementally.
