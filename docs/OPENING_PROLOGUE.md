# Elderwood Frontier — Opening Prologue and Adventurer's Guild

Status: **CANONICAL STORY DESIGN** (2026-11-22). First-pass gameplay is wired into the current Godot chapter. Items, balance, layouts, presentation, and all gameplay routes must still be verified in Godot. Do not treat this document as proof that testing passed.

## Story promise
The player begins as a fifteen-year-old who has spent childhood learning sword and ordinary magic in Elderwood Village. Their first quest is a coming-of-age rite. The first chapter should introduce adventuring as a vocation, then reveal that magic is awakening on a much larger scale. The five-year mentorship prologue transforms the teen adventurer into a twenty-year-old whose first meaningful build decisions emerge through story, not a detached class-creation screen.

### Chapter 1: The fifteenth birthday
- Town Elder **Elden**, not merchant Pip, greets the player after race selection, wishes them a happy fifteenth birthday, and explains that they have been raised and trained for independent adventuring.
- Four briar wolves in Pinewood Forest have been killing or threatening the village's sheep.
- Defeat all four, return to Elden, and complete the **Rite of Manhood**.
- Reward: **35 gold, two health potions, and two mana potions**. Elden directs the player to Stonehaven City's Adventurer's Guild.
- Pip stays a merchant; he does not issue this opening quest.

### Chapter 2: The Adventurer's Guild
The Guildhall is a public, prominent, clickable landmark in Stonehaven. Register with the Guild Master as a **D-rank** adventurer. The long-range rank ladder is **D → C → B → A → S** (rank promotion requirements are future work; no immediate jump in rank).
The Guild is a durable hub for quests, map intelligence, known regional threats, dungeons, lost sites, contracts, rewards, rumors, and rare portal sightings. Guild contracts should be available outside the critical path after the prologue.

Three starter contracts may be completed in any order:
1. **Raided caravan**: search for survivors and clues in the eastern forest, confront the Blackbriar bandits including the chief, return findings.
2. **Watchtower provisions**: receive a parcel from the Guild Master and deliver it to the eastern forest watchtower.
3. **Herbalist requisition**: collect ten herbs from East Pinewood.

After all three, the Guild Master asks the player to visit Stonehaven's lord.

### Chapter 3: The awakening ruin
The lord admits the city is terribly short-staffed, acknowledges the player was brave in defeating the bandits, and makes a humble request rather than ordering service. Travelers are mysteriously drawn to an old ruin. The player enters the dungeon, defeats its first mini-boss (working name **Waking Sentinel**), and retrieves:
- **An Inscribed Magic Stone**, bearing the prophecy: *Magic is our hope. It has the power to set us free. As it awakens, the world will change.*
- **Sentinel's Longsword**, a useful early upgrade.

The player returns to the lord. He rewards them with **50 gold**, asks that the message be delivered to the church, and offers voluntary training with his recruits and tutors. Neither military service nor oath is required.

### Chapter 4: Choice of mentor
The prophecy opens three potential paths:
- **Lord's household:** Captain Ser Aldric, swordsmanship, elemental magic, wards. Ordinary martial and magical disciplines.
- **Church:** Sister Elowen, healing, sacred wards, paladin combat. Priest/paladin abilities and later distinctive spells.
- **Black Hand (secret):** The Veiled Tutor, necromancy, blood magic, forbidden wards. Available only if the player discovered the Black Hand through its established cemetery/grimoire or cellar guard route.

The faction the player studies with is **not an irreversible class restriction**; future cross-training is possible. These are working mentor names and can be refined later. Every mentor should be an influential recurring character, with dialogue, personality, relationships, and later story consequences.

### Chapter 5: Five-year training montage
- Start at age 15; follow **five self-contained year-long training cycles** with one playable field mission per cycle.
- For each year, choose a focus from the mentor's disciplines; complete that year's assignment; report to the mentor; receive modest XP and a focused improvement; show a year transition.
- Progression uses existing ordinary XP, not late-game Transcendence Points. The first-pass reward is **60 XP per completed year**, five years totaling 300 XP before optional extra encounters; typical finishing goal **level 4–5**, with age 20 shown at the end.
- Show visible progress in skills through passive early combat improvements while distinct spell schools, ability VFX, skill trees, and progression UI are developed later.
- The five field missions currently share existing regions and interaction locations. Replace these initial short markers with actual varied quests (investigation, combat, rescue, training, ritual, escort) and authored mentor dialogue before declaring the montage content-complete.
- At year five, announce: **Five years have passed. You are twenty. Your apprenticeship is complete, and the main adventure begins.**

## Implementation notes (current first pass)
- Elder birthday introduction and four wolves: `scripts/village_interactions.gd`, `scripts/pinewood_forest.gd`.
- Guild, early quest interactions, ruin, mentors, time skips: `scripts/frontier/forsaken_chapter.gd`.
- Locations and quest items: `scripts/frontier/chapter_regions.gd`.
- State and backward-compatible save values: `scripts/frontier/adventure_state.gd`.
- Mentorship objectives, focus choices and working mentor identities: `scripts/frontier/mentorship.gd`.
- Existing Black Hand entry routes and necromancy content should remain functional. Avoid blocking exploration elsewhere simply because the narrative prologue has not advanced.

## Remaining work / do not claim complete
- Run Godot parser and playtests from a clean launch, through all four wolves, Elder reward, Stonehaven transfers, three guild quests in different orders, ruin miniboss, stone and sword reward, and all three mentor branches.
- Design original Guildhall sprite and an enterable interior with a Guild Master, board, map/archive and registration UI. The first pass reuses an existing civic-style building.
- Expand the watch captain handoff, herb models, caravan survivor clues and raid camp behavior into finished gameplay; avoid invisible collectible markers.
- Add unique scenes and quest mechanics for all fifteen mentor assignments, training cinematics/time-transition UI, actual school-specific unlocked spells, mentors' relationship arcs, and S-rank advancement.
- Verify inventory/saving: legacy village progress and chapter progress presently have different persistence boundaries; consumables and equipment require cross-region persistence tests.
- Preserve the Living Realms system: the magic stone foreshadows magical awakening and future portals; major realms remain authored, while minor realms may be generated and adaptive.

## Narrative design boundaries
- This is a **prologue**, not the main game's full plot.
- The guild serves as a repeatable content and discovery system throughout Elderwood.
- The lord, church and Black Hand should be interesting rather than simplistic good/evil labels; none may be framed as the universally correct route.
- Early players must feel proficient with sword and magic but still inexperienced in the broader world.
- The player retains agency; compulsory faction enrollment and permanent build locks are not part of this design.
