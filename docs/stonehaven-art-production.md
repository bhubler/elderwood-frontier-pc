# Elderwood Frontier NPC and spell production

## Playtest from Elderwood

Choose a character and head north to the Pinewood gate. From Pinewood follow
the main road to the Stonehaven gatehouse. Go through the arch and follow the
Stonehaven sign on the right. Click it or press E to enter the Eastward Quarter.

- Visit the four merchants and interact with E. Their role animations run in each conversation.
- Take the civic court road to see both guards drill, and follow its northern road to the watchtower.
- Take the Blackbriar caravan road to fight the bandit. Find the Old Woodland Trail from the graveyard to fight the cabin goblin.
- Follow the graveyard path to the crypt. Click its entrance or press E nearby. The original chapter routes lead to the Veiled Agent and the Oath Vault.
- Use the Stonehaven Gate marker in the Eastward Quarter to return to Pinewood. The chapter and the village still use their own backpack and equipment state. The chapter reuses your race choice when reached from the gate.

Open `scenes/frontier/forsaken_chapter.tscn` with F6 to start directly at the
graveyard. Both entry points share the existing Forsaken chapter save.

## Roster

The requested counts total 128. Use 68-pixel standing humans and align feet
with the existing player. Build individual silhouette and palette changes
over shared walk and idle clips where clothing and props permit it.

| Role | Catalog appearances | Placed in the world |
| --- | ---: | --- |
| Blacksmith | 10 | Garrik (1) |
| Alchemist | 10 | Gray-braided potion mixer (1) |
| General goods | 10 | Parcel merchant (1) |
| Merchant mage | 10 | Charm examiner (1) |
| City guard | 2 | Sword guard and spear guard (2) |
| City lord or noble | 10 | Councillor (1) |
| Bandits | 4 | Blackbriar bandit and chief (2) |
| Goblins | 4 | Cabin goblin and chief (2) |
| Black Hand | 5 | Veiled Agent and cellar guard (2) |
| Priest | 10 | Civic court priest (1) |
| Monk | 3 | Civic court monk (1) |
| Townspeople | 50 | Market sweeper and porter (2) |

Garrik belongs in Stonehaven. In the PC Forsaken development chapter, the
Veiled Agent receives the player after either the Forbidden Grimoire route or
Quiet Finn's cellar guard route. The Agent assigns and accepts the sealed
ledger from the Oath Vault. That chapter calls for dialogue and receiving the
ledger. The earlier browser quest *The Missing Ledger* also uses the Agent as
its contact and sends the player to the Blackbriar caravan. *The Empty Seat*
and Rellan belong to a separate browser initiation design.

The catalog has 128 appearances from 34 original animation sheets and 94
wardrobe variants. Seventeen have populated world placements. The remaining
111 are available in the editor playtest scene or through
`scripts/npc/npc_library.gd`. The sanctuary leader is ready for placement
when the sanctuary story is built.

Open `scenes/npc/roster_preview.tscn` and press F6 to inspect the catalog
beside the Human player. Tab changes roles, Q/E changes the appearance,
and 1–4 plays the available action clips. Use V to jump to the spell page.
On that page, 1–3 plays wind-up, active, and finish clips.

Guards are friendly and demonstrate their attacks as drills. Actual encounter
attacks land at contact or on projectile impact. Defeats save immediately so
reentry cannot restart a completed encounter. The Blackbriar chief uses a
hammer shockwave, and the goblin chief uses a wider overhead slam.

### Add an appearance

Create a SpriteFrames resource beside its atlas in
`art/characters/stonehaven/`. The sheets use 112-by-112 cells, with the
center of the ground contact at x=56 and the lowest boot at y=95. Use
`idle` and `walk` loops, then an `interact` clip for social actions or
`attack`, `hit`, and `defeat` clips for the corresponding combat
actions. On a four-frame attack, the third frame is the contact or release.
Add the sheet to the appropriate role in `npc_library.gd` with its wardrobe
count. Assign the SpriteFrames to `animated_npc.tscn`, or use
`NpcLibrary.create(sheet, wardrobe)` to place it at a ground anchor.

## Spell effects

| Spell or system | Gameplay status | Animation cues |
| --- | --- | --- |
| Fireball | Playable in the Pinewood route on main | Ember wind-up, release, directional bolt, impact on target or obstruction, ember fade |
| Summon Skeleton | Playable in the Forsaken chapter on main | Cold motes on wind-up, emerald ground circle on arrival, fading fragments on expiration |
| Ember Dart, Chill Needle, Mending Light | Earlier browser spells | Ember dart, narrow frost projectile, localized healing light |
| Sanguine Drain, Covenant of Thorns, Bone Spear | Earlier Maelis spell designs | Blood transfer, brief cast and sustained thorn accent, bone projectile and shatter |
| Fire skeleton and reinforced skeleton | Cross-school concepts | Preserve the summon silhouette, add fire embers or reinforced bone plates |
| Quickcast, dual casting and sustained buffs | System design | Effects use independent sprites, with persistent cues near feet or equipment. PC equipment and casting rules are pending. |
| Cursed objects and item or weapon runes | System concepts | Equipment-bound markings and short trigger pulses |

The browser and concept effects are viewable through the spell preview. They
have no PC gameplay bindings. Fireball and Summon Skeleton are the playable PC
spells in this batch. They use a shared Human cast animation, with the other
races retaining their existing character presentation and the same effects.

## Environment

Use the Wayfarer Inn and Stonehaven gatehouse as reference. The initial Stonehaven
building set covers the forge, alchemist, general store, mage shop, civic court,
chapel and monastery, guard barracks, and residences. The Forsaken Graveyard
crypt should have a clear entrance for the route into the Bonecaller chapter.
The Blackbriar caravan, woodland cabin, and Northern Frontier watchtower are
encounter landmarks. A roadside way shrine and an abandoned mill sluice add
two smaller points of interest.

## Verification

Godot 4.7.2 Linux headless checks covered startup dependencies, approach loading,
road quest persistence on reload of the Pinewood area, both Black Hand entry
routes and saved state, gate-to-chapter and chapter-to-gate round trips,
merchant actions, guard drills, bandit contact and defeat, Fireball impact,
Summon Skeleton wind-up and melee contact, and loading every roster appearance.
Windows keyboard and mouse playthrough, rendered visual checks, and balance
are still pending.
