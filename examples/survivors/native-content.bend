# Native display text; stable IDs match the simulation.
import Base
import character-policy.bend as CP

def name_0(id: U32) -> String:
  match id:
    case 0: "Starlight Letter"
    case 1: "Golden Rush"
    case 2: "Vinyl Arc"
    case 3: "Moon Orbit"
    case 4: "Warm Hearth"
    case 5: "Spotlight Snap"
    case 6: "Red Verse"
    case 7: "Indigo Rain"
    case 8: "Mirror Fan"
    case 9: "Poem Fragment"
    case 10: "Quiet Reflection"
    case 11: "Final Bow"
    case 12: "Ribbon Sweep"
    case 13: "Practice Line"
    case 14: "D-DAY Release"
    case 15: "Shadow Verse"
    case 16: "SHOOKY Mischief"
    case 17: "Astronaut Comet"
    case 18: "Stage Beam"
    case 19: "Leaf Orbit"
    case 20: "Indigo Composition"
    case 21: "Home Star"
    case 22: "Street Beat"
    case 23: "Dream Frame"
    case _: "Unknown"

def description_0(id: U32) -> String:
  match id:
    case 0: "Homing letters seek the nearest enemy."
    case 1: "Fast gold streaks fire in your movement direction."
    case 2: "Heavy records arc through approaching enemies."
    case 3: "Moon discs orbit you and strike nearby enemies."
    case 4: "A warm close aura burns approaching enemies."
    case 5: "Targeted spotlights strike enemies across the arena."
    case 6: "Burning verses pierce enemy formations."
    case 7: "Ink rain leaves damaging pools at selected locations."
    case 8: "A mirrored fan flies out and returns through pursuers."
    case 9: "Fragments of a poem appear around you as damaging fields."
    case 10: "Aimed mirror shards slow approaching enemies."
    case 11: "An infrequent stage flash strikes every visible enemy."
    case 12: "A broad ribbon strike sweeps the ground ahead."
    case 13: "Long gold thrusts strike along your movement direction."
    case 14: "A thrown sound charge detonates after a delay and damages an area."
    case 15: "Heavy radial sound blades slice through enemy formations."
    case 16: "Homing cookie sparks chase nearby enemies."
    case 17: "Falling comets explode among enemy clusters."
    case 18: "A long stage beam strikes enemies along a line."
    case 19: "Orbiting leaves defend the space close to you."
    case 20: "Ink fields pull enemies inward and repeatedly damage the chosen area."
    case 21: "An RJ-inspired orbiting star strikes nearby enemies and launches homing letters."
    case 22: "Leaves beat marks at your position. They arm after a delay and pulse at pursuers."
    case 23: "Surreal frames send projectiles outward in several directions."
    case _: ""

def name_1(id: U32) -> String:
  match id:
    case 0: "GOLDEN Drive"
    case 1: "Beat Clock"
    case 2: "Gallery Lens"
    case 3: "Long Encore"
    case 4: "Harmony Split"
    case 5: "Dance Sneakers"
    case 6: "Mirror Guard"
    case 7: "Warm Heart"
    case 8: "KOYA Focus"
    case 9: "Lyric Notebook"
    case 10: "TATA Curiosity"
    case 11: "RJ Comfort"
    case 12: "Golden Tempo"
    case 13: "Second Encore"
    case 14: "Jack in the Box"
    case 15: "Platinum Record"
    case 16: "Bass Pulse"
    case 17: "Home Cooking"
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

def name_2(id: U32) -> String:
  match id:
    case 0: "RM"
    case 1: "Jin"
    case 2: "SUGA"
    case 3: "j-hope"
    case 4: "Jimin"
    case 5: "V"
    case 6: "Jung Kook"
    case _: "Unknown"

def description_2(id: U32) -> String:
  match id:
    case 0: "Pulling ink fields organize the crowd. Pickup radius +50%."
    case 1: "An orbiting Home Star fires homing letters. Regenerates 1 health per second."
    case 2: "Delayed sound charges release a heavy burst. Might +20%."
    case 3: "Leave delayed beat pulses for pursuers. Movement speed +15%."
    case 4: "A mirrored fan cuts outward and returns. Armor +1."
    case 5: "Dream frames fire in several directions. Weapon cooldown -10%."
    case 6: "Fast gold streaks follow your movement. Might +10%; maximum health +25%."
    case _: ""

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

def name_4(id: U32) -> String:
  match id:
    case 0: "FACE of Glass"
    case 1: "Street Metronome"
    case 2: "Indigo Gallery"
    case 3: "Duet Reflection"
    case 4: "Mirror Resolve"
    case 5: "Unwritten Verse"
    case 6: "Cosmic Hospitality"
    case 7: "D-DAY Ember"
    case 8: "Golden Trajectory"
    case 9: "Namjooning"
    case 10: "Hopeful Footwork"
    case 11: "Composition of Wind"
    case _: "Unknown"

def description_4(id: U32) -> String:
  match id:
    case 0: "Might +35%, maximum health -30%."
    case 1: "Attack cooldown -20%, area -15%."
    case 2: "Area +35%, movement speed -15%."
    case 3: "Projectile count +1, attack cooldown +15%."
    case 4: "Armor +3, might -15%. Taking damage releases protective orbiting leaves, even without Leaf Orbit equipped."
    case 5: "Experience +30%; enemy health and count +20%. Poem Fragment and Final Bow gain 20% damage, plus 5% per Jack in the Box rank."
    case 6: "Pickup radius +100%, gold +25%."
    case 7: "Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick."
    case 8: "Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary."
    case 9: "Regenerates 2 health per second; maximum health +25%. With Warm Hearth or Leaf Orbit equipped, kills on periodic life-steal pulses restore 1 health each."
    case 10: "Movement speed +30%, healing received +30%."
    case 11: "Knockback +75%, area +15%. Vortex pull strength increases from 3 to 7."
    case _: ""

def name_5(id: U32) -> String:
  match id:
    case 0: "Daily Practice"
    case 1: "Stamina Training"
    case 2: "After-show Rest"
    case 3: "Stage Resolve"
    case 4: "Metronome Study"
    case 5: "Footwork Practice"
    case 6: "Museum Attention"
    case 7: "Poetry Journal"
    case 8: "Golden Keepsake"
    case 9: "Encore Promise"
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
    case 14: "Seven Together"
    case 15: "Every Road"
    case 16: "Night Arsenal"
    case 17: "Against Fate"
    case 18: "Overlord Breaker"
    case 19: "Seven Encores"
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
    case 14: "Unlock all 7 artists."
    case 15: "Unlock 5 stages."
    case 16: "Use 24 weapon types."
    case 17: "Revive during a run."
    case 18: "Defeat 20 bosses."
    case 19: "Win with all 7 artists."
    case _: ""

def name_8(id: U32) -> String:
  match id:
    case 0: "Letter Ensemble"
    case 1: "Golden Duet"
    case 2: "Midnight Session"
    case 3: "Slow Dancing Halo"
    case 4: "Namjooning Home"
    case 5: "D-DAY Supernova"
    case _: "Unknown"

def description_8(id: U32) -> String:
  match id:
    case 0: "Homing letters and targeted spotlights join pursuing cookie sparks."
    case 1: "Fast gold streaks and practice thrusts join outward dream frames."
    case 2: "Arcing records and radial sound blades join orbiting moon discs."
    case 3: "Orbiting moons and outward dream frames join piercing stage beams."
    case 4: "A warm aura and orbiting leaves join pulling ink fields."
    case 5: "Burning verses and falling comets join delayed sound explosions."
    case _: ""

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

def evolved_name(id: U32) -> String:
  match id:
    case 0: "Constellation Letter"
    case 1: "Golden Overdrive"
    case 2: "Midnight Rotation"
    case 3: "Astronaut Halo"
    case 4: "Homecoming Glow"
    case 5: "Stage Thunder"
    case 6: "Agust Inferno"
    case 7: "Namjooning Rain"
    case 8: "MUSE Reflection"
    case 9: "Indigo Manuscript"
    case 10: "FACE Stillness"
    case 11: "Encore Sky"
    case 12: "Silk Crescendo"
    case 13: "Perfect Take"
    case 14: "Agust Storm"
    case 15: "Daechwita Echo"
    case 16: "Cookie Chorus"
    case 17: "Homeward Meteor"
    case 18: "Golden Spotlight"
    case 19: "Museum Garden"
    case 20: "Order in Chaos"
    case 21: "RJ Constellation"
    case 22: "HOPE Block Party"
    case 23: "TATA Dreamscape"
    case _: "Unknown"

def evolved_description(id: U32) -> String:
  match id:
    case 0: "Starlight Letter alternates with Spotlight Snap. Damage +120%; area +35%."
    case 1: "Golden Rush alternates with Practice Line. Damage +120%; area +35%."
    case 2: "Vinyl Arc alternates with Shadow Verse. Damage +120%; area +35%."
    case 3: "Moon Orbit alternates with Dream Frame. Damage +120%; area +35%."
    case 4: "Warm Hearth alternates with Leaf Orbit. Damage +120%; area +35%."
    case 5: "Spotlight Snap alternates with Starlight Letter. Damage +120%; area +35%."
    case 6: "Red Verse alternates with Astronaut Comet. Damage +120%; area +35%."
    case 7: "Indigo Rain alternates with Indigo Composition. Damage +120%; area +35%."
    case 8: "Mirror Fan alternates with Poem Fragment. Damage +120%; area +35%."
    case 9: "Poem Fragment alternates with Dream Frame. Damage +120%; area +35%."
    case 10: "Quiet Reflection alternates with Spotlight Snap. Damage +120%; area +35%."
    case 11: "Final Bow alternates with Astronaut Comet. Damage +120%; area +35%."
    case 12: "Ribbon Sweep alternates with Warm Hearth. Damage +120%; area +35%."
    case 13: "Practice Line alternates with Mirror Fan. Damage +120%; area +35%."
    case 14: "D-DAY Release alternates with Astronaut Comet. Damage +120%; area +35%."
    case 15: "Shadow Verse alternates with Vinyl Arc. Damage +120%; area +35%."
    case 16: "SHOOKY Mischief alternates with Red Verse. Damage +120%; area +35%."
    case 17: "Astronaut Comet alternates with D-DAY Release. Damage +120%; area +35%."
    case 18: "Stage Beam alternates with Poem Fragment. Damage +120%; area +35%."
    case 19: "Leaf Orbit alternates with Warm Hearth. Damage +120%; area +35%."
    case 20: "Indigo Composition alternates with Moon Orbit. Damage +120%; area +35%."
    case 21: "Orbiting Home Stars launch homing letters and add targeted slowing spotlights. Damage +120%; area +35%."
    case 22: "Street Beat alternates with Indigo Composition. Damage +120%; area +35%."
    case 23: "Dream Frame alternates with Spotlight Snap. Damage +120%; area +35%."
    case _: ""

def starter(id: U32) -> U32: CP.starter(id)

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
    case 12: "Find Silk Spool in Forgotten Graveyard."
    case 13: "Available from the start."
    case 14: "Defeat 100 enemies across your runs."
    case 15: "Available from the start."
    case 16: "Find SHOOKY Crumb in Wisp Marsh."
    case 17: "Find Astronaut Map in Infernal Maw."
    case 18: "Find Golden Filament in Midnight Library."
    case 19: "Available from the start."
    case 20: "Available from the start."
    case 21: "Available from the start."
    case 22: "Find Street Cassette in Frozen Pass."
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
    case 14: "Unlock all 7 artists."
    case 15: "Unlock 5 stages."
    case 16: "Use 24 weapon types."
    case 17: "Revive during a run."
    case 18: "Defeat 20 bosses."
    case 19: "Win with all 7 artists."
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
    case 0: "Starlight Letter Lv8 + Beat Clock Lv1; claim a chest to evolve into Constellation Letter."
    case 1: "Golden Rush Lv8 + Golden Tempo Lv1; claim a chest to evolve into Golden Overdrive."
    case 2: "Vinyl Arc Lv8 + Gallery Lens Lv1; claim a chest to evolve into Midnight Rotation."
    case 3: "Moon Orbit Lv8 + Harmony Split Lv1; claim a chest to evolve into Astronaut Halo."
    case 4: "Warm Hearth Lv8 + RJ Comfort Lv1; claim a chest to evolve into Homecoming Glow."
    case 5: "Spotlight Snap Lv8 + Harmony Split Lv1; claim a chest to evolve into Stage Thunder."
    case 6: "Red Verse Lv8 + GOLDEN Drive Lv1; claim a chest to evolve into Agust Inferno."
    case 7: "Indigo Rain Lv8 + Long Encore Lv1; claim a chest to evolve into Namjooning Rain."
    case 8: "Mirror Fan Lv8 + TATA Curiosity Lv1; claim a chest to evolve into MUSE Reflection."
    case 9: "Poem Fragment Lv8 + Long Encore Lv1; claim a chest to evolve into Indigo Manuscript."
    case 10: "Quiet Reflection Lv8 + Beat Clock Lv1; claim a chest to evolve into FACE Stillness."
    case 11: "Final Bow Lv8 + Lyric Notebook Lv1; claim a chest to evolve into Encore Sky."
    case 12: "Ribbon Sweep Lv8 + Warm Heart Lv1; claim a chest to evolve into Silk Crescendo."
    case 13: "Practice Line Lv8 + Golden Tempo Lv1; claim a chest to evolve into Perfect Take."
    case 14: "D-DAY Release Lv8 + Gallery Lens Lv1; claim a chest to evolve into Agust Storm."
    case 15: "Shadow Verse Lv8 + GOLDEN Drive Lv1; claim a chest to evolve into Daechwita Echo."
    case 16: "SHOOKY Mischief Lv8 + Harmony Split Lv1; claim a chest to evolve into Cookie Chorus."
    case 17: "Astronaut Comet Lv8 + Gallery Lens Lv1; claim a chest to evolve into Homeward Meteor."
    case 18: "Stage Beam Lv8 + Long Encore Lv1; claim a chest to evolve into Golden Spotlight."
    case 19: "Leaf Orbit Lv8 + Mirror Guard Lv1; claim a chest to evolve into Museum Garden."
    case 20: "Indigo Composition Lv8 + KOYA Focus Lv1; claim a chest to evolve into Order in Chaos."
    case 21: "Home Star Lv8 + TATA Curiosity Lv1; claim a chest to evolve into RJ Constellation."
    case 22: "Street Beat Lv8 + Long Encore Lv1; claim a chest to evolve into HOPE Block Party."
    case 23: "Dream Frame Lv8 + Golden Tempo Lv1; claim a chest to evolve into TATA Dreamscape."
    case _: ""
def union_recipe(id: U32) -> String:
  match id:
    case 0: "Starlight Letter + Spotlight Snap, both Lv8 or Lv9; claim a chest for Letter Ensemble. The second weapon is consumed."
    case 1: "Golden Rush + Practice Line, both Lv8 or Lv9; claim a chest for Golden Duet. The second weapon is consumed."
    case 2: "Vinyl Arc + Shadow Verse, both Lv8 or Lv9; claim a chest for Midnight Session. The second weapon is consumed."
    case 3: "Moon Orbit + Dream Frame, both Lv8 or Lv9; claim a chest for Slow Dancing Halo. The second weapon is consumed."
    case 4: "Warm Hearth + Leaf Orbit, both Lv8 or Lv9; claim a chest for Namjooning Home. The second weapon is consumed."
    case 5: "Red Verse + Astronaut Comet, both Lv8 or Lv9; claim a chest for D-DAY Supernova. The second weapon is consumed."
    case _: ""
def recipe(category: U32,+id: U32) -> String:
  match category:
    case 0: weapon_recipe(id)
    case 8: union_recipe(id)
    case _: ""
