# Elderwood Frontier — Mobile World Integration Plan

This branch is a staging area. Do not merge into main until each feature has been reviewed and tested in Godot 4.7. Keep licensed sprite packs local and out of GitHub.

## Existing mobile-version locations and systems to preserve
- Elderwood Village and Wayfarer Inn
- Forsaken Graveyard; three-chamber Crypt of the Bonecaller; necromancer boss; forbidden grimoire
- Summon Skeleton: 45 mana, 35-second duration; Conjuration progression
- Stonehaven: Church of the Dawn (Sister Amara), Moonleaf Apothecary (Nessa Vale), blacksmith Garrik, Eastward Quarter underground Black Hand hideout, Quiet Finn
- Northern Frontier: Ancient Temple Ruins, Northern Crossroads, Ranger Camp, Whispering Hollow, Abandoned Watchtower
- Road to the Watchtower: Kael, bandit captain, return to Kael
- World persistence: region, day, discoveries, quest state, spell unlocks, enemies, chests, plants, player HP/MP and position
- Spell purchases: Ember Dart 65; Chill Needle 85; Mending Light 90

## Revised Black Hand discovery and recruitment
**Shared rule:** Discovering the hideout is not automatic membership. Both discovery paths unlock the same initiation quest; remember the entry method for future dialogue.

### Path A: Forbidden magic
1. Defeat the necromancer in the graveyard crypt and obtain the forbidden grimoire.
2. Learn its dark spell (initially Summon Skeleton, subject to exact mobile implementation).
3. Cast the learned spell. Trigger a one-time Black Hand emissary encounter.
4. Emissary congratulates the player for discovering and daring to use forbidden magic, reveals the Stonehaven cellar location, and grants access.
5. Arriving at the hideout offers the initiation quest.

### Path B: Trial of blood
1. Independently locate the Stonehaven cellar entrance.
2. Fight a Black Hand guard; victory is required for admission.
3. Black Hand representative explains the guard was an intentional strength test: a guard who cannot survive does not belong.
4. Offer the same initiation quest.

### State model
- `grimoire_acquired`, `dark_spell_learned`, `dark_spell_cast`
- `black_hand_entry_method`: `none | grimoire | guard`
- `black_hand_emissary_met`, `black_hand_guard_defeated`
- `black_hand_hideout_known`, `black_hand_access_granted`
- `black_hand_initiation_offered`, `black_hand_initiation_started`, `black_hand_member`

Rules: never replay the emissary or guard introduction after the entry path is resolved; guard cannot bypass combat by simply interacting; learning the spell without casting it must not trigger the emissary; initiation completion and membership remain distinct.

## Integration stages
1. **Data foundation**: stable IDs, flags, item/spell definitions, quest journal and save compatibility.
2. **Cemetery/crypt**: necromancer encounter, grimoire, spell learning and casting.
3. **Stonehaven**: city map, NPCs, shops and underground entrance.
4. **Black Hand**: both admission routes, shared initiation quest and dialogue variations.
5. **Northern Frontier**: ranger camp, watchtower, temple and hollow quest states.
6. **Expansion**: crafting, equipment, combat depth, magic progression, dungeon generation, companions and guilds.

## Asset direction
- Necromancer: illustrated isometric/top-down-compatible sprite matching village art; bone helmet and either a bone staff or scythe.
- Do not assume an image is production-ready until transparent background, sprite dimensions, directional frames, animation and scale are verified.
- Await user-provided reference picture before finalizing character design.

## Validation gates
- No regression to Elderwood Village, Wayfarer Inn, inventory, player movement or race selection.
- Never assume Godot runtime validation from a GitHub commit.
- Keep purchased asset packs out of the public repository.
- Merge one stage at a time after user tests locally.
