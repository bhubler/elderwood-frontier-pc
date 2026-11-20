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

| Role | Target | Integrated in first batch |
| --- | ---: | --- |
| Blacksmith | 10 | Garrik |
| Alchemist | 10 | Gray-braided potion mixer |
| General goods | 10 | Parcel merchant |
| Merchant mage | 10 | Charm examiner |
| City guard | 2 | Sword guard and spear guard |
| City lord or noble | 10 | Later batch |
| Bandits | 4 | Hatchet bandit |
| Goblins | 4 | Hooked-knife goblin |
| Black Hand | 5 | Veiled Agent |
| Priest | 10 | Later batch |
| Monk | 3 | Later batch |
| Townspeople | 50 | Later batch |

Garrik belongs in Stonehaven. In the PC Forsaken development chapter, the
Veiled Agent receives the player after either the Forbidden Grimoire route or
Quiet Finn's cellar guard route. The Agent assigns and accepts the sealed
ledger from the Oath Vault. That chapter calls for dialogue and receiving the
ledger. The earlier browser quest *The Missing Ledger* also uses the Agent as
its contact and sends the player to the Blackbriar caravan. *The Empty Seat*
and Rellan belong to a separate browser initiation design.

The initial batch integrates 9 of 128 appearances. Later rows are production
targets. Guards are friendly and demonstrate their attacks as drills. The
encounter enemies use the attack clip's contact frame for live damage and
save their defeat immediately so reentry cannot restart a completed encounter.

## Spell effects

| Spell or system | Gameplay status | Animation cues |
| --- | --- | --- |
| Fireball | Playable in the Pinewood route on main | Ember wind-up, release, directional bolt, impact on target or obstruction, ember fade |
| Summon Skeleton | Playable in the Forsaken chapter on main | Cold motes on wind-up, emerald ground circle on arrival, fading fragments on expiration |
| Ember Dart, Chill Needle, Mending Light | Earlier browser spells | Ember dart, narrow frost projectile, localized healing light |
| Sanguine Drain, Covenant of Thorns, Bone Spear | Earlier Maelis spell designs | Blood transfer, brief cast and sustained thorn accent, bone projectile and shatter |
| Fire skeleton and reinforced skeleton | Cross-school concepts | Preserve the summon silhouette, add fire embers or reinforced bone plates |
| Quickcast, dual casting and sustained buffs | System design | Local hand effects leave room for concurrent projectiles, and persistent cues stay close to feet or equipment |
| Cursed objects and item or weapon runes | System concepts | Equipment-bound markings and short trigger pulses |

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
merchant actions, guard drills, bandit contact and defeat, and Fireball impact.
Windows keyboard and mouse playthrough, rendered visual checks, and balance
are still pending.
