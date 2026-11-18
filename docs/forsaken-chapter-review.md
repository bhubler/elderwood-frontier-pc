# Forsaken chapter review

Open `scenes/frontier/forsaken_chapter.tscn` in Godot and run the current scene with **F6**. F5 still opens Elderwood Village. The chapter starts in the Forsaken Graveyard with its own race selection and a separate save.

| Key | Action |
| --- | --- |
| WASD or arrows, Shift | Move, run |
| E | Use the nearest marked interaction |
| Space | Attack a nearby enemy |
| L | Study the Forbidden Grimoire once acquired |
| Q | Cast Summon Skeleton |
| J, I | Quest journal, backpack |
| Esc | Close the journal or backpack |

## Test in this order

1. **Graveyard and crypt.** Enter the Crypt of the Bonecaller from the graveyard's north path. Cross the antechamber, defeat the Restless Skeleton in the ossuary, and defeat the Bonecaller in the ritual chamber. Recover the grimoire at the lectern and inspect it in the backpack. You can equip the starter sword there before fighting.
2. **Forbidden magic route.** Press L while holding the grimoire. Check that learning alone brings no emissary. Press Q and confirm the summon spends 45 mana, lasts 35 seconds during active play, and unlocks an emissary interaction. Speak to the emissary with E. Return to the graveyard and follow the road east to Stonehaven. Check that the drainage door is visible and the cellar guard does not attack.
3. **Guard route on a fresh chapter save.** Go straight from the graveyard to Stonehaven. Talk to Quiet Finn in the Eastward Quarter to reveal the Hidden Drainage Door. Try the hideout entrance before defeating the guard, then defeat him and enter. Check the Veiled Agent's dialogue for the trial explanation.
4. **Shared initiation.** On either route, check the journal before speaking to the Veiled Agent, after accepting, and after turning in the sealed ledger from the oath vault. Confirm access alone grants no reputation, the ledger is removed on delivery, and membership awards +10 reputation once.
5. **Reload and village.** Restart F6 and confirm that defeated enemies, chapter quest items, learned spell, experience, Conjuration uses, recruitment route and membership persist. Restart F5 and check race selection, village movement, villager dialogue, inn entry and return, and inventory/equipment.

For a fresh chapter playthrough, close the scene and move `forsaken_chapter_v1.cfg` out of Godot's project user-data folder. Open that folder from **Project → Open User Data Folder** in the editor. The chapter resumes at the graveyard after reload. Its race, equipment changes, HP, mana, summon and position are session-only.

## Verified

- Godot 4.6.3 headless editor import and startup for the chapter, main village and existing necromancer prototype.
- The scripted smoke run covered both routes through shared initiation, encounter gating, successful and rejected casts, summon assistance and expiration, one-time loot and rewards, quest-state reload and starter village equipment/inn setup. It positions the player directly and drives the input handlers.
- Fixed two startup errors found during checking. The inn interior now attaches after the village scene finishes setting up, and the older necromancer prototype no longer has a helper name that conflicts with Godot's native ellipse method.
- The branch adds scripts, scenes, tests and documentation. Existing local-only artwork ignores continue to cover the Penzilla and Wilderness packs.

Run the scripted checks from the project root with `godot --headless --editor --import --quit` followed by `godot --headless --script res://tests/frontier_smoke.gd`.

## Pending

- Windows Godot 4.7 testing, full manual keyboard and mouse playthrough, visual review, pacing, enemy balance, and testing with locally installed art.
- Production Stonehaven map and its shops, including Garrik's blacksmith. Elderwood Village has no blacksmith.
- Live world travel from the village into this chapter, final terrain/character art and animation, wider magic and perk trees, a general-purpose inventory/save migration, more Black Hand quests, and Northern Frontier content including Kael's watchtower.
- The sealed ledger and oath vault are provisional details for exercising the shared initiation loop. XP grants character points and repeat casts raise Conjuration rank. Perk spending and rank-based bonuses are future work.
