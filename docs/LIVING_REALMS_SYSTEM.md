# Elderwood Frontier — Living Realms & Living Threat System

Status: CANONICAL DESIGN — 2026-11-22
Scope: Godot 4.7 PC RPG; incremental implementation. This is a design specification, not a claim that systems are implemented.

## Core principles
- Most regular enemies, regions and regional bosses use fixed strength bands. Becoming powerful must allow the player to dominate earlier areas.
- Select legendary enemies have powerful authored baselines and may use explicitly bounded variants.
- Only designated special portal encounters and endgame challenges use player-informed generation. Generated encounter stats are frozen at creation; no hidden mid-fight rubber-banding.
- Adaptive difficulty challenges a build without nullifying its defining strengths. Avoid blanket immunity, unavoidable counters, or punishment for optimized play.
- A realm may be easy, roughly matched, or deliberately overwhelming. Not every portal matches player power.
- Do not gate story completion behind reaching the character level cap (provisionally 1,000). Transcendence is a late-game unlock, separate from ordinary progression.

## Realm categories
1. **Authored major realms**: notable size, established geography, culture, lore, quests and unique bosses. Persistent, hand-built and integrated into narrative progression.
2. **Generated minor realms**: compact modular layouts, ranging from a few dungeon rooms to a small settlement plus surrounding wilderness; seeded variations in theme, paths, encounters, loot and optional discoveries.
3. **Legendary portal discoveries**: rare generated portals can lead to authored landmarks, clues or hooks for major realms.

Portals are a recurring magical world phenomenon, not merely a UI for selecting dungeons. Provide visible discoverable portal landmarks and clear enter/exit interactions. Use existing region tiles and approved art standards; avoid committing purchased art.

## Combat Power Analyzer (future implementation)
Gather:
- sustained damage (real fight windows, avoiding trivial targets);
- burst damage and cooldowns;
- effective survivability (health, mitigation, dodge, healing, lifesteal);
- damage schools, control, summons and mobility;
- observed performance against benchmark encounters.

Maintain separate **estimated capability** (loadout and spells) and **observed capability** (combat telemetry). Use confidence scores and fall back to a conservative authored threat tier when there is not enough data. Never use player level or maximum DPS alone.

## Encounter construction
1. Select encounter class: ordinary, legendary, adaptive, or overwhelming.
2. Select realm theme, compatible modular layout and enemy ecology.
3. For adaptive encounters, derive a bounded threat budget from capability estimates and desired difficulty; cap counters and avoid hard immunities.
4. Choose boss archetype, ability package, adds and phases; calculate effective HP from DPS, anticipated attack uptime and target duration only as an initial estimate.
5. Validate with simulated/automated combat checks when available, then persist a **seed**, version, chosen stats and abilities before entering. Do not re-scale on player death or re-entry.
6. Reward exploration and skillful success with appropriate loot and rare materials; avoid making an infinite generator trivialize authored rewards or the economy.

## Performance and persistence
- Generate realm layout/metadata from seed when portal is discovered or entered, not continuously each frame.
- Cache lightweight realm descriptors; stream or instantiate only needed rooms and enemies.
- Persist opened portal IDs, seeds, completed encounters and discovered rewards; distinguish fresh runs from resumed saves.
- Reuse scenes, tiles, NPCs and effects. Add new art only for genuinely missing content.
- Give every generated realm a reliable return route; preserve player return location and avoid save/load traps.

## Incremental build sequence
1. Inspect existing combat, world transitions, save data, random dungeon and portal entry conventions before integration.
2. Add isolated capability-snapshot and telemetry services with test fixtures; no effect on current enemies.
3. Add deterministic realm descriptors and seeded layouts using existing art and map components.
4. Implement one small portal realm with an entrance, exit, fixed enemy, optional adaptive boss, reward and save/resume.
5. Add threat archetype packages, more themes, rare lore hooks, balancing tools and Transcendence connections.
6. Test ordinary builds, highly optimized builds, summons, lifesteal, heavy crowd control, burst-only setups, fresh saves and resumed saves.

## First acceptance target
One optional portal in an existing playable outdoor area leads to a compact instanced realm; generation is deterministic from its seed, the exit works, the ordinary world remains fixed-level, and the adaptive boss's snapshot does not change after creation. The feature is not complete until tested from the normal in-game entrance.
