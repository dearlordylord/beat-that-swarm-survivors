# Native catalogs; stable IDs match the Bend simulation.
import Base

def name_0(id: U32) -> String:
  match id:
    case 0: "Spark Wand"
    case 1: "Shard Knives"
    case 2: "Gravedigger Axe"
    case 3: "Moon Discs"
    case 4: "Wormwood Charm"
    case 5: "Thunder Bell"
    case 6: "Ember Orb"
    case 7: "Hallowed Dew"
    case 8: "Returning Cross"
    case 9: "Rune Seal"
    case 10: "Frost Needle"
    case 11: "Banishment Sign"
    case 12: "Funeral Lash"
    case 13: "Watchman's Spear"
    case 14: "Powder Vessel"
    case 15: "Dusk Scythe"
    case 16: "Bee Swarm"
    case 17: "Star Fragment"
    case 18: "Light Thread"
    case 19: "Thorn Wreath"
    case 20: "Dark Whirlpool"
    case 21: "Lantern Familiar"
    case 22: "Storm Mine"
    case 23: "Twilight Prism"
    case _: "Unknown"

def description_0(id: U32) -> String:
  match id:
    case 0: "Seeks the nearest enemy with aimed sparks."
    case 1: "Throws fast knives in your movement direction."
    case 2: "Heavy axes arc through approaching enemies."
    case 3: "Orbiting discs strike enemies around you."
    case 4: "A close aura burns enemies that approach."
    case 5: "Lightning strikes enemies across the battlefield."
    case 6: "Fireballs pierce through enemy formations."
    case 7: "Leaves damaging pools at impact locations."
    case 8: "A cross flies out and returns through pursuers."
    case 9: "Runes appear around you and damage their area."
    case 10: "Aimed ice projectiles slow approaching enemies."
    case 11: "An infrequent ritual strikes every visible enemy."
    case 12: "A broad strike sweeps the ground ahead."
    case 13: "Long thrusts strike along your movement direction."
    case 14: "Bombs detonate after a delay and damage an area."
    case 15: "Heavy scythes slice through enemy formations."
    case 16: "Homing insects seek nearby prey."
    case 17: "Celestial impacts burst among enemy clusters."
    case 18: "A long beam strikes enemies along a line."
    case 19: "A thorny close area punishes the nearby horde."
    case 20: "Vortices repeatedly damage selected areas."
    case 21: "A circling spirit strikes nearby enemies and launches homing bolts."
    case 22: "Leaves traps behind you for pursuers."
    case 23: "Multidirectional projectiles strike several sides."
    case _: ""

def cost_0(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case 18: 0
    case 19: 0
    case 20: 0
    case 21: 0
    case 22: 0
    case 23: 0
    case _: 0

def condition_stat_0(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case 6: 63
    case 7: 63
    case 8: 63
    case 9: 63
    case 10: 63
    case 11: 63
    case 12: 63
    case 13: 63
    case 14: 63
    case 15: 63
    case 16: 63
    case 17: 63
    case 18: 63
    case 19: 63
    case 20: 63
    case 21: 63
    case 22: 63
    case 23: 63
    case _: 63

def condition_value_0(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case 18: 0
    case 19: 0
    case 20: 0
    case 21: 0
    case 22: 0
    case 23: 0
    case _: 0

def name_1(id: U32) -> String:
  match id:
    case 0: "Seal of Might"
    case 1: "Hourglass"
    case 2: "Giant's Lens"
    case 3: "Eternal Candle"
    case 4: "Forked Amulet"
    case 5: "Wanderer's Boots"
    case 6: "Bone Armor"
    case 7: "Scarlet Heart"
    case 8: "Lodestone"
    case 9: "Ancient Chronicle"
    case 10: "Shadow Clover"
    case 11: "Living Branch"
    case 12: "Tailwind"
    case 13: "Second Wind"
    case 14: "Cursed Crown"
    case 15: "Golden Tooth"
    case 16: "Storm Ring"
    case 17: "Healing Dew"
    case _: "Unknown"

def description_1(id: U32) -> String:
  match id:
    case 0: "All weapon damage +10% per rank."
    case 1: "Attack cooldown -7% per rank."
    case 2: "Weapon and effect area +10% per rank."
    case 3: "Weapon duration +15% per rank."
    case 4: "One additional projectile per rank."
    case 5: "Movement speed +10% per rank."
    case 6: "Reduces incoming damage by 1 per rank."
    case 7: "Maximum health +20% per rank."
    case 8: "Experience pickup radius +25% per rank."
    case 9: "Experience gained +10% per rank."
    case 10: "Luck +10% per rank, improving normal enemy gold and healing drops."
    case 11: "Regenerates 1 health per second per rank."
    case 12: "Projectile speed +15% per rank."
    case 13: "One additional full-health revival per rank."
    case 14: "Enemy health and count +10% per rank; experience and gold +10% per rank."
    case 15: "Gold gained +15% per rank."
    case 16: "Enemy knockback +15% per rank."
    case 17: "Healing from pickups and regeneration +20% per rank."
    case _: ""

def cost_1(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case _: 0

def condition_stat_1(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case 6: 63
    case 7: 63
    case 8: 63
    case 9: 63
    case 10: 63
    case 11: 63
    case 12: 63
    case 13: 63
    case 14: 63
    case 15: 63
    case 16: 63
    case 17: 63
    case _: 63

def condition_value_1(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case _: 0

def name_2(id: U32) -> String:
  match id:
    case 0: "Mira"
    case 1: "Corvin"
    case 2: "Agatha"
    case 3: "Seraph"
    case 4: "Bran"
    case 5: "Eira"
    case 6: "Nox"
    case 7: "Lumen"
    case _: "Unknown"

def description_2(id: U32) -> String:
  match id:
    case 0: "Reliable aimed attacks. Might +10%."
    case 1: "An agile fighter. Movement speed +15%."
    case 2: "Close defense. Regenerates 1 health per second."
    case 3: "Returning weapon. Armor +1."
    case 4: "Heavy attacks. Maximum health +25%."
    case 5: "Slowing attacks. Weapon cooldown -10%."
    case 6: "Piercing blades. Might +20%; enemy health +15%."
    case 7: "A circling spirit with homing bolts. Pickup radius +50%."
    case _: ""

def cost_2(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 250
    case 2: 500
    case 3: 750
    case 4: 1000
    case 5: 1500
    case 6: 2200
    case 7: 3000
    case _: 0

def condition_stat_2(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 20
    case 2: 22
    case 3: 24
    case 4: 30
    case 5: 23
    case 6: 20
    case 7: 28
    case _: 63

def condition_value_2(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 100
    case 2: 120
    case 3: 1
    case 4: 2
    case 5: 1
    case 6: 3000
    case 7: 10
    case _: 0

def name_3(id: U32) -> String:
  match id:
    case 0: "Forgotten Graveyard"
    case 1: "Midnight Library"
    case 2: "Wisp Marsh"
    case 3: "Frozen Pass"
    case 4: "Infernal Maw"
    case _: "Unknown"

def description_3(id: U32) -> String:
  match id:
    case 0: "An open field beneath the moon. The skeletal horde never lets you rest."
    case 1: "Forbidden shelves and relentless pursuers. Keep an escape route open."
    case 2: "Ancient wetlands and venomous creatures. Keep moving to survive."
    case 3: "A cold expanse beneath the charge of swift northern beasts."
    case 4: "The final frontier: furious waves and ancient overlords."
    case _: ""

def cost_3(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 500
    case 2: 1000
    case 3: 1800
    case 4: 2800
    case _: 0

def condition_stat_3(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 22
    case 2: 25
    case 3: 30
    case 4: 23
    case _: 63

def condition_value_3(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 180
    case 2: 20
    case 3: 5
    case 4: 2
    case _: 0

def name_4(id: U32) -> String:
  match id:
    case 0: "Glass Heart"
    case 1: "Eternal Rhythm"
    case 2: "Heavenly Dome"
    case 3: "Twins"
    case 4: "Stone Vow"
    case 5: "Forbidden Knowledge"
    case 6: "Greedy Magnet"
    case 7: "Undying Flame"
    case 8: "Falling Star"
    case 9: "Living Tree"
    case 10: "Rescue Wind"
    case 11: "Voice of the Storm"
    case _: "Unknown"

def description_4(id: U32) -> String:
  match id:
    case 0: "Might +35%, maximum health -30%."
    case 1: "Attack cooldown -20%, area -15%."
    case 2: "Area +35%, movement speed -15%."
    case 3: "Projectile count +1, attack cooldown +15%."
    case 4: "Armor +3, might -15%. Taking damage releases protective orbiting thorns, even without a Thorn Wreath."
    case 5: "Experience +30%; enemy health and count +20%. Rune Seal and Banishment Sign gain 20% damage, plus 5% per Cursed Crown rank."
    case 6: "Pickup radius +100%, gold +25%."
    case 7: "Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick."
    case 8: "Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary."
    case 9: "Regenerates 2 health per second; maximum health +25%. With Wormwood Charm or Thorn Wreath equipped, kills on periodic life-steal pulses restore 1 health each."
    case 10: "Movement speed +30%, healing received +30%."
    case 11: "Knockback +75%, area +15%. Vortex pull strength increases from 3 to 7."
    case _: ""

def cost_4(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case _: 0

def condition_stat_4(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case 6: 63
    case 7: 63
    case 8: 63
    case 9: 63
    case 10: 63
    case 11: 63
    case _: 63

def condition_value_4(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case _: 0

def name_5(id: U32) -> String:
  match id:
    case 0: "Memory of Might"
    case 1: "Life Thread"
    case 2: "Quiet Recovery"
    case 3: "Steel Will"
    case 4: "Quick Thought"
    case 5: "Light Step"
    case 6: "Shard Calling"
    case 7: "Knowledge Legacy"
    case 8: "Golden Memory"
    case 9: "Spare Fate"
    case _: "Unknown"

def description_5(id: U32) -> String:
  match id:
    case 0: "Damage +5% per rank."
    case 1: "Maximum health +10% per rank."
    case 2: "Regenerates 1 health per second per rank."
    case 3: "Armor +1 per rank."
    case 4: "Attack cooldown -3% per rank."
    case 5: "Movement speed +5% per rank."
    case 6: "Pickup radius +15% per rank."
    case 7: "Experience +5% per rank."
    case 8: "Gold +10% per rank."
    case 9: "One additional revival per rank."
    case _: ""

def cost_5(id: U32) -> U32:
  match id:
    case 0: 150
    case 1: 120
    case 2: 180
    case 3: 250
    case 4: 300
    case 5: 100
    case 6: 120
    case 7: 250
    case 8: 150
    case 9: 1500
    case _: 0

def condition_stat_5(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case 6: 63
    case 7: 63
    case 8: 63
    case 9: 63
    case _: 63

def condition_value_5(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case _: 0

def name_6(id: U32) -> String:
  match id:
    case 0: "Bone Wanderer"
    case 1: "Midnight Bat"
    case 2: "Hungry Corpse"
    case 3: "Marsh Slime"
    case 4: "Wild Wolf"
    case 5: "Cursed Knight"
    case 6: "Plague Rat"
    case 7: "Wandering Spirit"
    case 8: "Ash Spider"
    case 9: "Bone Archer"
    case 10: "Blood Cultist"
    case 11: "Mimic"
    case 12: "Ice Guard"
    case 13: "Fire Imp"
    case 14: "Venom Toad"
    case 15: "Twilight Harpy"
    case 16: "Grave Golem"
    case 17: "Scarab Swarm"
    case 18: "Ancient Treant"
    case 19: "Mist Reaper"
    case 20: "Graveyard Warden"
    case 21: "Abyssal Librarian"
    case 22: "Marsh Queen"
    case 23: "Frost Sovereign"
    case 24: "Ash Prince"
    case 25: "Bone Colossus"
    case 26: "Swarm Matriarch"
    case 27: "Star Devourer"
    case 28: "Last Door Guardian"
    case 29: "Night Incarnate"
    case 30: "Dawn Reaper"
    case _: "Unknown"

def description_6(id: U32) -> String:
  match id:
    case 0: "skeleton"
    case 1: "bat"
    case 2: "zombie"
    case 3: "slime"
    case 4: "wolf"
    case 5: "knight"
    case 6: "rat"
    case 7: "ghost"
    case 8: "spider"
    case 9: "archer"
    case 10: "cultist"
    case 11: "mimic"
    case 12: "iceguard"
    case 13: "imp"
    case 14: "toad"
    case 15: "harpy"
    case 16: "golem"
    case 17: "swarm"
    case 18: "ent"
    case 19: "reaper"
    case 20: "boss"
    case 21: "boss"
    case 22: "boss"
    case 23: "boss"
    case 24: "boss"
    case 25: "boss"
    case 26: "boss"
    case 27: "boss"
    case 28: "boss"
    case 29: "boss"
    case 30: "A lethal hunter after dawn; immune to slowing, burning, and knockback."
    case _: ""

def cost_6(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case 18: 0
    case 19: 0
    case 20: 0
    case 21: 0
    case 22: 0
    case 23: 0
    case 24: 0
    case 25: 0
    case 26: 0
    case 27: 0
    case 28: 0
    case 29: 0
    case _: 0

def condition_stat_6(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case 6: 63
    case 7: 63
    case 8: 63
    case 9: 63
    case 10: 63
    case 11: 63
    case 12: 63
    case 13: 63
    case 14: 63
    case 15: 63
    case 16: 63
    case 17: 63
    case 18: 63
    case 19: 63
    case 20: 63
    case 21: 63
    case 22: 63
    case 23: 63
    case 24: 63
    case 25: 63
    case 26: 63
    case 27: 63
    case 28: 63
    case 29: 63
    case _: 63

def condition_value_6(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case 18: 0
    case 19: 0
    case 20: 0
    case 21: 0
    case 22: 0
    case 23: 0
    case 24: 0
    case 25: 0
    case 26: 0
    case 27: 0
    case 28: 0
    case 29: 0
    case _: 0

def name_7(id: U32) -> String:
  match id:
    case 0: "First Spark"
    case 1: "Hunter"
    case 2: "Legion's Fall"
    case 3: "Nightmare's Nightmare"
    case 4: "Heavy Purse"
    case 5: "Treasury"
    case 6: "Stand Firm"
    case 7: "Halfway There"
    case 8: "Until Dawn"
    case 9: "Night Veteran"
    case 10: "Transformation"
    case 11: "Weapon Alchemist"
    case 12: "Awakening"
    case 13: "Ascension"
    case 14: "Gathering of Heroes"
    case 15: "Every Road"
    case 16: "Night Arsenal"
    case 17: "Against Fate"
    case 18: "Overlord Breaker"
    case 19: "Eight Fates"
    case _: "Unknown"

def description_7(id: U32) -> String:
  match id:
    case 0: "Defeat 100 enemies."
    case 1: "Defeat 1,000 enemies."
    case 2: "Defeat 10,000 enemies."
    case 3: "Defeat 50,000 enemies."
    case 4: "Earn 1,000 gold in total."
    case 5: "Earn 10,000 gold in total."
    case 6: "Survive for 60 seconds."
    case 7: "Survive for 300 seconds."
    case 8: "Win a run."
    case 9: "Win 10 runs."
    case 10: "Obtain your first evolution."
    case 11: "Obtain 12 evolutions."
    case 12: "Reach level 20 in a run."
    case 13: "Reach level 50 in a run."
    case 14: "Unlock 8 heroes."
    case 15: "Unlock 5 stages."
    case 16: "Use 24 weapon types."
    case 17: "Revive during a run."
    case 18: "Defeat 20 bosses."
    case 19: "Win with all 8 heroes."
    case _: ""

def cost_7(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case 6: 0
    case 7: 0
    case 8: 0
    case 9: 0
    case 10: 0
    case 11: 0
    case 12: 0
    case 13: 0
    case 14: 0
    case 15: 0
    case 16: 0
    case 17: 0
    case 18: 0
    case 19: 0
    case _: 0

def condition_stat_7(id: U32) -> U32:
  match id:
    case 0: 20
    case 1: 20
    case 2: 20
    case 3: 20
    case 4: 21
    case 5: 21
    case 6: 22
    case 7: 22
    case 8: 23
    case 9: 23
    case 10: 24
    case 11: 24
    case 12: 25
    case 13: 25
    case 14: 26
    case 15: 27
    case 16: 28
    case 17: 29
    case 18: 30
    case 19: 31
    case _: 63

def condition_value_7(id: U32) -> U32:
  match id:
    case 0: 100
    case 1: 1000
    case 2: 10000
    case 3: 50000
    case 4: 1000
    case 5: 10000
    case 6: 60
    case 7: 300
    case 8: 1
    case 9: 10
    case 10: 1
    case 11: 12
    case 12: 20
    case 13: 50
    case 14: 8
    case 15: 5
    case 16: 24
    case 17: 1
    case 18: 20
    case 19: 8
    case _: 0

def name_8(id: U32) -> String:
  match id:
    case 0: "Storm Choir"
    case 1: "Spearstorm"
    case 2: "Reaper Wheel"
    case 3: "Prismatic Halo"
    case 4: "Briar Heart"
    case 5: "Sunfall"
    case _: "Unknown"

def description_8(id: U32) -> String:
  match id:
    case 0: "Homing sparks and thunderbolts unite with a pursuing swarm."
    case 1: "Piercing spear thrusts and swift knives join outward spectral volleys."
    case 2: "Arcing axes and radial scythes join an orbiting defensive wheel."
    case 3: "Orbiting discs and spectral volleys join fast piercing light rays."
    case 4: "A burning aura and circling thorns join lingering pulling vortices."
    case 5: "Piercing fireballs and descending meteors join delayed bomb explosions."
    case _: ""

def cost_8(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case _: 0

def condition_stat_8(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 63
    case 2: 63
    case 3: 63
    case 4: 63
    case 5: 63
    case _: 63

def condition_value_8(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case 4: 0
    case 5: 0
    case _: 0

def name_9(id: U32) -> String:
  match id:
    case 0: "Standard"
    case 1: "Inverse"
    case 2: "Endless"
    case 3: "Trial"
    case _: "Unknown"

def description_9(id: U32) -> String:
  match id:
    case 0: "Survive ten minutes and defeat the night."
    case 1: "A harsher night with stronger enemies and greater rewards."
    case 2: "The horde keeps growing beyond the dawn. Survive as long as you can."
    case 3: "A five-minute challenge with accelerated waves. Permanent upgrades are disabled."
    case _: ""

def cost_9(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 0
    case 2: 0
    case 3: 0
    case _: 0

def condition_stat_9(id: U32) -> U32:
  match id:
    case 0: 63
    case 1: 25
    case 2: 23
    case 3: 30
    case _: 63

def condition_value_9(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 20
    case 2: 1
    case 3: 3
    case _: 0

def name(category: U32,+id: U32) -> String:
  match category:
    case 0: name_0(id)
    case 1: name_1(id)
    case 2: name_2(id)
    case 3: name_3(id)
    case 4: name_4(id)
    case 5: name_5(id)
    case 6: name_6(id)
    case 7: name_7(id)
    case 8: name_8(id)
    case 9: name_9(id)
    case _: ""

def description(category: U32,+id: U32) -> String:
  match category:
    case 0: description_0(id)
    case 1: description_1(id)
    case 2: description_2(id)
    case 3: description_3(id)
    case 4: description_4(id)
    case 5: description_5(id)
    case 6: description_6(id)
    case 7: description_7(id)
    case 8: description_8(id)
    case 9: description_9(id)
    case _: ""

def cost(category: U32,+id: U32) -> U32:
  match category:
    case 0: cost_0(id)
    case 1: cost_1(id)
    case 2: cost_2(id)
    case 3: cost_3(id)
    case 4: cost_4(id)
    case 5: cost_5(id)
    case 6: cost_6(id)
    case 7: cost_7(id)
    case 8: cost_8(id)
    case 9: cost_9(id)
    case _: 0

def condition_stat(category: U32,+id: U32) -> U32:
  match category:
    case 0: condition_stat_0(id)
    case 1: condition_stat_1(id)
    case 2: condition_stat_2(id)
    case 3: condition_stat_3(id)
    case 4: condition_stat_4(id)
    case 5: condition_stat_5(id)
    case 6: condition_stat_6(id)
    case 7: condition_stat_7(id)
    case 8: condition_stat_8(id)
    case 9: condition_stat_9(id)
    case _: 0

def condition_value(category: U32,+id: U32) -> U32:
  match category:
    case 0: condition_value_0(id)
    case 1: condition_value_1(id)
    case 2: condition_value_2(id)
    case 3: condition_value_3(id)
    case 4: condition_value_4(id)
    case 5: condition_value_5(id)
    case 6: condition_value_6(id)
    case 7: condition_value_7(id)
    case 8: condition_value_8(id)
    case 9: condition_value_9(id)
    case _: 0

def count(id: U32) -> U32:
  match id:
    case 0: 24
    case 1: 18
    case 2: 8
    case 3: 5
    case 4: 12
    case 5: 10
    case 6: 31
    case 7: 20
    case 8: 6
    case 9: 4
    case _: 0

def evolved_name(id: U32) -> String:
  match id:
    case 0: "Storm Canticle"
    case 1: "Thousand Cuts"
    case 2: "Harvest Wheel"
    case 3: "Solar Crown"
    case 4: "Wasteland Heart"
    case 5: "Heaven's Verdict"
    case 6: "Dragon Breath"
    case 7: "Sea of Dawn"
    case 8: "Paladin's Fate"
    case 9: "Abyssal Alphabet"
    case 10: "Absolute Zero"
    case 11: "Final Star"
    case 12: "Crimson Dawn"
    case 13: "Celestial Pike"
    case 14: "Red Carnival"
    case 15: "Fate Reaper"
    case 16: "Royal Hive"
    case 17: "Meteor Shower"
    case 18: "Eternal Beam"
    case 19: "Garden of Retribution"
    case 20: "Event Horizon"
    case 21: "Wisp Flock"
    case 22: "Thunderfield"
    case 23: "Universal Spectrum"
    case _: "Unknown"

def evolved_description(id: U32) -> String:
  match id:
    case 0: "Homing sparks alternate with targeted thunderbolts. Damage +120%; area +35%."
    case 1: "Knife fans alternate with long piercing spear thrusts. Damage +120%; area +35%."
    case 2: "Arcing axes alternate with radial piercing scythes. Damage +120%; area +35%."
    case 3: "Orbiting discs alternate with outward spectral volleys. Damage +120%; area +35%."
    case 4: "A close burning aura joins orbiting defensive thorns. Damage +120%; area +35%."
    case 5: "Targeted lightning alternates with homing sparks. Damage +120%; area +35%."
    case 6: "Piercing fireballs alternate with delayed meteor impacts. Damage +120%; area +35%."
    case 7: "Lingering pools alternate with damaging vortex fields. Damage +120%; area +35%."
    case 8: "Returning crosses alternate with surrounding rune fields. Damage +120%; area +35%."
    case 9: "Surrounding rune fields alternate with outward prism volleys. Damage +120%; area +35%."
    case 10: "Slowing ice needles alternate with targeted thunderbolts. Damage +120%; area +35%."
    case 11: "Wide banishment rituals alternate with explosive meteor impacts. Damage +120%; area +35%."
    case 12: "Broad forward lashes alternate with a close damaging aura. Damage +120%; area +35%."
    case 13: "Long piercing spear thrusts alternate with returning crosses. Damage +120%; area +35%."
    case 14: "Delayed bombs alternate with descending explosive meteors. Damage +120%; area +35%."
    case 15: "Radial scythes alternate with heavy arcing axes. Damage +120%; area +35%."
    case 16: "Homing swarms alternate with piercing fireballs. Damage +120%; area +35%."
    case 17: "Descending meteors alternate with delayed bomb explosions. Damage +120%; area +35%."
    case 18: "Fast piercing light rays alternate with surrounding rune fields. Damage +120%; area +35%."
    case 19: "Orbiting thorns alternate with a close damaging aura. Damage +120%; area +35%."
    case 20: "Lingering vortex fields alternate with orbiting discs. Damage +120%; area +35%."
    case 21: "Orbiting spirits launch homing bolts and add targeted freezing thunderbolts. Damage +120%; area +35%."
    case 22: "Persistent pulsing traps alternate with damaging vortex fields. Damage +120%; area +35%."
    case 23: "Outward spectral volleys alternate with targeted thunderbolts. Damage +120%; area +35%."
    case _: ""

def meta_max(id: U32) -> U32:
  match id:
    case 0: 5
    case 1: 5
    case 2: 5
    case 3: 3
    case 4: 5
    case 5: 5
    case 6: 5
    case 7: 5
    case 8: 5
    case 9: 2
    case _: 0

def starter(id: U32) -> U32:
  match id:
    case 0: 0
    case 1: 1
    case 2: 4
    case 3: 8
    case 4: 2
    case 5: 10
    case 6: 15
    case 7: 21
    case _: 0

def evolution_passive(id: U32) -> U32:
  match id:
    case 0: 1
    case 1: 12
    case 2: 2
    case 3: 4
    case 4: 11
    case 5: 4
    case 6: 0
    case 7: 3
    case 8: 10
    case 9: 3
    case 10: 1
    case 11: 9
    case 12: 7
    case 13: 12
    case 14: 2
    case 15: 0
    case 16: 4
    case 17: 2
    case 18: 3
    case 19: 6
    case 20: 8
    case 21: 10
    case 22: 3
    case 23: 12
    case _: 0

# Player-facing unlock requirements and chest recipes.
def hint_0(id: U32) -> String:
  match id:
    case 0: "Available from the start."
    case 1: "Available from the start."
    case 2: "Available from the start."
    case 3: "Available from the start."
    case 4: "Available from the start."
    case 5: "Available from the start."
    case 6: "Available from the start."
    case 7: "Available from the start."
    case 8: "Available from the start."
    case 9: "Available from the start."
    case 10: "Available from the start."
    case 11: "Available from the start."
    case 12: "Find Gravedigger's Cord in Forgotten Graveyard."
    case 13: "Available from the start."
    case 14: "Defeat 100 enemies across your runs."
    case 15: "Available from the start."
    case 16: "Find Amber Queen in Wisp Marsh."
    case 17: "Find Fallen Star in Infernal Maw."
    case 18: "Find Dawn Filament in Midnight Library."
    case 19: "Available from the start."
    case 20: "Available from the start."
    case 21: "Available from the start."
    case 22: "Find Storm Fuse in Frozen Pass."
    case 23: "Available from the start."
    case _: ""
def hint_1(id: U32) -> String:
  match id:
    case 0: ""
    case 1: ""
    case 2: ""
    case 3: ""
    case 4: ""
    case 5: ""
    case 6: ""
    case 7: ""
    case 8: ""
    case 9: ""
    case 10: ""
    case 11: ""
    case 12: ""
    case 13: ""
    case 14: ""
    case 15: ""
    case 16: ""
    case 17: ""
    case _: ""
def hint_2(id: U32) -> String:
  match id:
    case 0: "Available from the start."
    case 1: "Defeat 100 enemies across your runs. Purchase: 250 gold."
    case 2: "Survive for 2 minutes in a single run. Purchase: 500 gold."
    case 3: "Obtain a weapon evolution. Purchase: 750 gold."
    case 4: "Defeat 2 bosses across your runs. Purchase: 1000 gold."
    case 5: "Win a run. Purchase: 1500 gold."
    case 6: "Defeat 3,000 enemies across your runs. Purchase: 2200 gold."
    case 7: "Discover 10 different weapons. Purchase: 3000 gold."
    case _: ""
def hint_3(id: U32) -> String:
  match id:
    case 0: "Available from the start."
    case 1: "Survive for 3 minutes in a single run. Purchase: 500 gold."
    case 2: "Reach level 20 in a single run. Purchase: 1000 gold."
    case 3: "Defeat 5 bosses across your runs. Purchase: 1800 gold."
    case 4: "Win 2 runs. Purchase: 2800 gold."
    case _: ""
def hint_4(id: U32) -> String:
  match id:
    case 0: ""
    case 1: ""
    case 2: ""
    case 3: ""
    case 4: ""
    case 5: ""
    case 6: ""
    case 7: ""
    case 8: ""
    case 9: ""
    case 10: ""
    case 11: ""
    case _: ""
def hint_5(id: U32) -> String:
  match id:
    case 0: "Maximum rank 5. Base cost 150 gold; cost increases with rank."
    case 1: "Maximum rank 5. Base cost 120 gold; cost increases with rank."
    case 2: "Maximum rank 5. Base cost 180 gold; cost increases with rank."
    case 3: "Maximum rank 3. Base cost 250 gold; cost increases with rank."
    case 4: "Maximum rank 5. Base cost 300 gold; cost increases with rank."
    case 5: "Maximum rank 5. Base cost 100 gold; cost increases with rank."
    case 6: "Maximum rank 5. Base cost 120 gold; cost increases with rank."
    case 7: "Maximum rank 5. Base cost 250 gold; cost increases with rank."
    case 8: "Maximum rank 5. Base cost 150 gold; cost increases with rank."
    case 9: "Maximum rank 2. Base cost 1500 gold; cost increases with rank."
    case _: ""
def hint_6(id: U32) -> String:
  match id:
    case 0: ""
    case 1: ""
    case 2: ""
    case 3: ""
    case 4: ""
    case 5: ""
    case 6: ""
    case 7: ""
    case 8: ""
    case 9: ""
    case 10: ""
    case 11: ""
    case 12: ""
    case 13: ""
    case 14: ""
    case 15: ""
    case 16: ""
    case 17: ""
    case 18: ""
    case 19: ""
    case 20: ""
    case 21: ""
    case 22: ""
    case 23: ""
    case 24: ""
    case 25: ""
    case 26: ""
    case 27: ""
    case 28: ""
    case 29: ""
    case 30: ""
    case _: ""
def hint_7(id: U32) -> String:
  match id:
    case 0: "Defeat 100 enemies."
    case 1: "Defeat 1,000 enemies."
    case 2: "Defeat 10,000 enemies."
    case 3: "Defeat 50,000 enemies."
    case 4: "Earn 1,000 gold in total."
    case 5: "Earn 10,000 gold in total."
    case 6: "Survive for 60 seconds."
    case 7: "Survive for 300 seconds."
    case 8: "Win a run."
    case 9: "Win 10 runs."
    case 10: "Obtain your first evolution."
    case 11: "Obtain 12 evolutions."
    case 12: "Reach level 20 in a run."
    case 13: "Reach level 50 in a run."
    case 14: "Unlock 8 heroes."
    case 15: "Unlock 5 stages."
    case 16: "Use 24 weapon types."
    case 17: "Revive during a run."
    case 18: "Defeat 20 bosses."
    case 19: "Win with all 8 heroes."
    case _: ""
def hint_8(id: U32) -> String:
  match id:
    case 0: ""
    case 1: ""
    case 2: ""
    case 3: ""
    case 4: ""
    case 5: ""
    case _: ""
def hint_9(id: U32) -> String:
  match id:
    case 0: "Available from the start."
    case 1: "Reach level 20 in a single run."
    case 2: "Win a run."
    case 3: "Defeat 3 bosses across your runs."
    case _: ""
def hint(category: U32,+id: U32) -> String:
  match category:
    case 0: hint_0(id)
    case 1: hint_1(id)
    case 2: hint_2(id)
    case 3: hint_3(id)
    case 4: hint_4(id)
    case 5: hint_5(id)
    case 6: hint_6(id)
    case 7: hint_7(id)
    case 8: hint_8(id)
    case 9: hint_9(id)
    case _: ""
def weapon_recipe(id: U32) -> String:
  match id:
    case 0: "Spark Wand Lv8 + Hourglass Lv1; claim a chest to evolve into Storm Canticle."
    case 1: "Shard Knives Lv8 + Tailwind Lv1; claim a chest to evolve into Thousand Cuts."
    case 2: "Gravedigger Axe Lv8 + Giant's Lens Lv1; claim a chest to evolve into Harvest Wheel."
    case 3: "Moon Discs Lv8 + Forked Amulet Lv1; claim a chest to evolve into Solar Crown."
    case 4: "Wormwood Charm Lv8 + Living Branch Lv1; claim a chest to evolve into Wasteland Heart."
    case 5: "Thunder Bell Lv8 + Forked Amulet Lv1; claim a chest to evolve into Heaven's Verdict."
    case 6: "Ember Orb Lv8 + Seal of Might Lv1; claim a chest to evolve into Dragon Breath."
    case 7: "Hallowed Dew Lv8 + Eternal Candle Lv1; claim a chest to evolve into Sea of Dawn."
    case 8: "Returning Cross Lv8 + Shadow Clover Lv1; claim a chest to evolve into Paladin's Fate."
    case 9: "Rune Seal Lv8 + Eternal Candle Lv1; claim a chest to evolve into Abyssal Alphabet."
    case 10: "Frost Needle Lv8 + Hourglass Lv1; claim a chest to evolve into Absolute Zero."
    case 11: "Banishment Sign Lv8 + Ancient Chronicle Lv1; claim a chest to evolve into Final Star."
    case 12: "Funeral Lash Lv8 + Scarlet Heart Lv1; claim a chest to evolve into Crimson Dawn."
    case 13: "Watchman's Spear Lv8 + Tailwind Lv1; claim a chest to evolve into Celestial Pike."
    case 14: "Powder Vessel Lv8 + Giant's Lens Lv1; claim a chest to evolve into Red Carnival."
    case 15: "Dusk Scythe Lv8 + Seal of Might Lv1; claim a chest to evolve into Fate Reaper."
    case 16: "Bee Swarm Lv8 + Forked Amulet Lv1; claim a chest to evolve into Royal Hive."
    case 17: "Star Fragment Lv8 + Giant's Lens Lv1; claim a chest to evolve into Meteor Shower."
    case 18: "Light Thread Lv8 + Eternal Candle Lv1; claim a chest to evolve into Eternal Beam."
    case 19: "Thorn Wreath Lv8 + Bone Armor Lv1; claim a chest to evolve into Garden of Retribution."
    case 20: "Dark Whirlpool Lv8 + Lodestone Lv1; claim a chest to evolve into Event Horizon."
    case 21: "Lantern Familiar Lv8 + Shadow Clover Lv1; claim a chest to evolve into Wisp Flock."
    case 22: "Storm Mine Lv8 + Eternal Candle Lv1; claim a chest to evolve into Thunderfield."
    case 23: "Twilight Prism Lv8 + Tailwind Lv1; claim a chest to evolve into Universal Spectrum."
    case _: ""
def union_recipe(id: U32) -> String:
  match id:
    case 0: "Spark Wand + Thunder Bell, both Lv8 or Lv9; claim a chest for Storm Choir. The second weapon is consumed."
    case 1: "Shard Knives + Watchman's Spear, both Lv8 or Lv9; claim a chest for Spearstorm. The second weapon is consumed."
    case 2: "Gravedigger Axe + Dusk Scythe, both Lv8 or Lv9; claim a chest for Reaper Wheel. The second weapon is consumed."
    case 3: "Moon Discs + Twilight Prism, both Lv8 or Lv9; claim a chest for Prismatic Halo. The second weapon is consumed."
    case 4: "Wormwood Charm + Thorn Wreath, both Lv8 or Lv9; claim a chest for Briar Heart. The second weapon is consumed."
    case 5: "Ember Orb + Star Fragment, both Lv8 or Lv9; claim a chest for Sunfall. The second weapon is consumed."
    case _: ""
def recipe(category: U32,+id: U32) -> String:
  match category:
    case 0: weapon_recipe(id)
    case 8: union_recipe(id)
    case _: ""
