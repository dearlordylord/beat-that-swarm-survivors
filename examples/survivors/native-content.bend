# Native display text; stable IDs match the simulation.
import Base
import character-policy.bend as CP

def name_0(id: U32) -> String:
  match id:
    case 0: "Guiding Letter"
    case 1: "Forward Drive"
    case 2: "Vinyl Arc"
    case 3: "Moon Orbit"
    case 4: "Hearth Glow"
    case 5: "Stage Flash"
    case 6: "Burning Verse"
    case 7: "Ink Rain"
    case 8: "Silk Return"
    case 9: "Scattered Lines"
    case 10: "Quiet Reflection"
    case 11: "Curtain Flash"
    case 12: "Ribbon Sweep"
    case 13: "Practice Thrust"
    case 14: "Pressure Break"
    case 15: "Shadow Verse"
    case 16: "Mischief Crumb"
    case 17: "Homeward Comet"
    case 18: "Spotlight Lance"
    case 19: "Garden Orbit"
    case 20: "Gathering Ink"
    case 21: "Hearth Orbit"
    case 22: "Afterbeat"
    case 23: "Waking Frame"
    case _: "Unknown"

def description_0(id: U32) -> String:
  match id:
    case 0: "Homing letters seek the nearest enemy."
    case 1: "Fast gold streaks fire in your movement direction."
    case 2: "Throws records in an arc through enemies."
    case 3: "Moon discs orbit you and damage nearby enemies."
    case 4: "Damages enemies in a small aura around you."
    case 5: "Places short-lived strikes at targeted enemy positions."
    case 6: "Fires piercing verses that burn enemies."
    case 7: "Creates persistent damaging ink pools."
    case 8: "A silver fan flies out and returns through enemies."
    case 9: "Creates damaging paper fields around you."
    case 10: "Fires aimed mirror shards that slow enemies on hit."
    case 11: "An infrequent flash damages enemies across a large area."
    case 12: "Sweeps a wide ribbon through enemies ahead of you."
    case 13: "Thrusts a long gold strike in your movement direction."
    case 14: "Throws a sound charge that explodes after a short delay."
    case 15: "Fires piercing sound blades in several directions."
    case 16: "Homing crumbs chase nearby enemies."
    case 17: "Drops comets that explode after a short delay."
    case 18: "Fires a fast piercing beam along a line."
    case 19: "Leaves orbit you and damage nearby enemies."
    case 20: "Ink fields pull enemies inward and repeatedly damage the chosen area."
    case 21: "An orbiting light strikes nearby enemies and fires homing sparks."
    case 22: "Leaves beat marks at your position. They arm after a delay and pulse at nearby enemies."
    case 23: "Frames fire projectiles outward in several directions."
    case _: ""

def name_1(id: U32) -> String:
  match id:
    case 0: "Drive Weight"
    case 1: "Pocket Metronome"
    case 2: "Wideglass Lens"
    case 3: "Silk Spool"
    case 4: "Split Fork"
    case 5: "Street Soles"
    case 6: "Lacquer Guard"
    case 7: "Hearth Locket"
    case 8: "Pressed Leaf"
    case 9: "Field Notebook"
    case 10: "Odd Die"
    case 11: "Travel Mug"
    case 12: "Flight Feather"
    case 13: "Spare Wick"
    case 14: "Restless Box"
    case 15: "Gilt Record"
    case 16: "Bass Cabinet"
    case 17: "Steam Bowl"
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
    case 0: "Grove Scribe"
    case 1: "Hearth Voyager"
    case 2: "Ash Pianist"
    case 3: "Sunlit Stepper"
    case 4: "Swanward"
    case 5: "Sepia Wanderer"
    case 6: "Gilt Hare"
    case _: "Unknown"

def description_2(id: U32) -> String:
  match id:
    case 0: "Ink fields gather enemies. Hold three for 1 second to release a finishing pulse. Pickup radius +50%."
    case 1: "An orbiting lantern fires homing letters. Every third orbit pushes enemies away. Regenerates 1 health per second."
    case 2: "Stand still to bank three notes. The next Pressure Break deals +75% damage. Moving preserves full notes. Weapon damage +20%."
    case 3: "Walk to leave delayed beat marks for pursuers. Movement speed +15%."
    case 4: "A fan cuts out and returns. Previously struck enemies take +30% damage on return. Armor +1."
    case 5: "Radial frames echo from their original position after 0.45 seconds at half damage. Weapon cooldown -10%."
    case 6: "Three successful starter hits within 2 seconds release a piercing punch. Weapon damage +10%; base maximum health 125."
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
    case 0: "Glass Resolve"
    case 1: "Street Metronome"
    case 2: "Open Gallery"
    case 3: "Duet Reflection"
    case 4: "Mirror Resolve"
    case 5: "Unwritten Verse"
    case 6: "Cosmic Hospitality"
    case 7: "Banked Ember"
    case 8: "Gilt Trajectory"
    case 9: "Garden Rest"
    case 10: "Hopeful Footwork"
    case 11: "Composition of Wind"
    case _: "Unknown"

def description_4(id: U32) -> String:
  match id:
    case 0: "Might +35%, maximum health -30%."
    case 1: "Attack cooldown -20%, area -15%."
    case 2: "Area +35%, movement speed -15%."
    case 3: "Projectile count +1, attack cooldown +15%."
    case 4: "Armor +3, might -15%. Taking damage releases protective orbiting leaves, even without Garden Orbit equipped."
    case 5: "Experience +30%; enemy health and count +20%. Scattered Lines and Curtain Flash gain 20% damage, plus 5% per Restless Box rank."
    case 6: "Pickup radius +100%, gold +25%."
    case 7: "Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick."
    case 8: "Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary."
    case 9: "Regenerates 2 health per second; maximum health +25%. With Hearth Glow or Garden Orbit equipped, kills on periodic life-steal pulses restore 1 health each."
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
    case 4: "Garden Rest Home"
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
    case 0: "Guiding Constellation"
    case 1: "Gilt Overdrive"
    case 2: "Midnight Rotation"
    case 3: "Lunar Parade"
    case 4: "Homecoming Glow"
    case 5: "Stage Thunder"
    case 6: "Cinder Canticle"
    case 7: "Collected Rain"
    case 8: "Silver Reprise"
    case 9: "Living Manuscript"
    case 10: "Stillwater Glass"
    case 11: "Encore Sky"
    case 12: "Silk Crescendo"
    case 13: "Perfect Take"
    case 14: "Pressure Storm"
    case 15: "Night Resonance"
    case 16: "Crumb Chorus"
    case 17: "Homeward Meteor"
    case 18: "Gilt Spotlight"
    case 19: "Museum Garden"
    case 20: "Quiet Composition"
    case 21: "Traveling Hearth"
    case 22: "Street Crescendo"
    case 23: "Waking Gallery"
    case _: "Unknown"

def evolved_description(id: U32) -> String:
  match id:
    case 0: "Alternates Guiding Letter with Stage Flash. Damage +120%; area +35%."
    case 1: "Alternates Forward Drive with Practice Thrust. Damage +120%; area +35%."
    case 2: "Alternates Vinyl Arc with Shadow Verse. Damage +120%; area +35%."
    case 3: "Alternates Moon Orbit with Waking Frame. Damage +120%; area +35%."
    case 4: "Alternates Hearth Glow with Garden Orbit. Damage +120%; area +35%."
    case 5: "Alternates Stage Flash with Guiding Letter. Damage +120%; area +35%."
    case 6: "Alternates Burning Verse with Homeward Comet. Damage +120%; area +35%."
    case 7: "Alternates Ink Rain with Gathering Ink. Damage +120%; area +35%."
    case 8: "Alternates Silk Return with Scattered Lines. Damage +120%; area +35%."
    case 9: "Alternates Scattered Lines with Waking Frame. Damage +120%; area +35%."
    case 10: "Alternates Quiet Reflection with Stage Flash. Damage +120%; area +35%."
    case 11: "Alternates Curtain Flash with Homeward Comet. Damage +120%; area +35%."
    case 12: "Alternates Ribbon Sweep with Hearth Glow. Damage +120%; area +35%."
    case 13: "Alternates Practice Thrust with Silk Return. Damage +120%; area +35%."
    case 14: "Alternates Pressure Break with Homeward Comet. Damage +120%; area +35%."
    case 15: "Alternates Shadow Verse with Vinyl Arc. Damage +120%; area +35%."
    case 16: "Alternates Mischief Crumb with Burning Verse. Damage +120%; area +35%."
    case 17: "Alternates Homeward Comet with Pressure Break. Damage +120%; area +35%."
    case 18: "Alternates Spotlight Lance with Scattered Lines. Damage +120%; area +35%."
    case 19: "Alternates Garden Orbit with Hearth Glow. Damage +120%; area +35%."
    case 20: "Alternates Gathering Ink with Moon Orbit. Damage +120%; area +35%."
    case 21: "Orbiting lights fire homing sparks and add targeted slowing strikes. Damage +120%; area +35%."
    case 22: "Alternates Afterbeat with Gathering Ink. Damage +120%; area +35%."
    case 23: "Alternates Waking Frame with Stage Flash. Damage +120%; area +35%."
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
    case 8: 6
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
    case 21: 11
    case 22: 5
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
    case 0: "Guiding Letter Lv8 + Pocket Metronome Lv1; claim a chest to evolve into Guiding Constellation."
    case 1: "Forward Drive Lv8 + Flight Feather Lv1; claim a chest to evolve into Gilt Overdrive."
    case 2: "Vinyl Arc Lv8 + Wideglass Lens Lv1; claim a chest to evolve into Midnight Rotation."
    case 3: "Moon Orbit Lv8 + Split Fork Lv1; claim a chest to evolve into Lunar Parade."
    case 4: "Hearth Glow Lv8 + Travel Mug Lv1; claim a chest to evolve into Homecoming Glow."
    case 5: "Stage Flash Lv8 + Split Fork Lv1; claim a chest to evolve into Stage Thunder."
    case 6: "Burning Verse Lv8 + Drive Weight Lv1; claim a chest to evolve into Cinder Canticle."
    case 7: "Ink Rain Lv8 + Silk Spool Lv1; claim a chest to evolve into Collected Rain."
    case 8: "Silk Return Lv8 + Lacquer Guard Lv1; claim a chest to evolve into Silver Reprise."
    case 9: "Scattered Lines Lv8 + Silk Spool Lv1; claim a chest to evolve into Living Manuscript."
    case 10: "Quiet Reflection Lv8 + Pocket Metronome Lv1; claim a chest to evolve into Stillwater Glass."
    case 11: "Curtain Flash Lv8 + Field Notebook Lv1; claim a chest to evolve into Encore Sky."
    case 12: "Ribbon Sweep Lv8 + Hearth Locket Lv1; claim a chest to evolve into Silk Crescendo."
    case 13: "Practice Thrust Lv8 + Flight Feather Lv1; claim a chest to evolve into Perfect Take."
    case 14: "Pressure Break Lv8 + Wideglass Lens Lv1; claim a chest to evolve into Pressure Storm."
    case 15: "Shadow Verse Lv8 + Drive Weight Lv1; claim a chest to evolve into Night Resonance."
    case 16: "Mischief Crumb Lv8 + Split Fork Lv1; claim a chest to evolve into Crumb Chorus."
    case 17: "Homeward Comet Lv8 + Wideglass Lens Lv1; claim a chest to evolve into Homeward Meteor."
    case 18: "Spotlight Lance Lv8 + Silk Spool Lv1; claim a chest to evolve into Gilt Spotlight."
    case 19: "Garden Orbit Lv8 + Lacquer Guard Lv1; claim a chest to evolve into Museum Garden."
    case 20: "Gathering Ink Lv8 + Pressed Leaf Lv1; claim a chest to evolve into Quiet Composition."
    case 21: "Hearth Orbit Lv8 + Travel Mug Lv1; claim a chest to evolve into Traveling Hearth."
    case 22: "Afterbeat Lv8 + Street Soles Lv1; claim a chest to evolve into Street Crescendo."
    case 23: "Waking Frame Lv8 + Flight Feather Lv1; claim a chest to evolve into Waking Gallery."
    case _: ""
def union_recipe(id: U32) -> String:
  match id:
    case 0: "Guiding Letter + Stage Flash, both Lv8 or Lv9; claim a chest for Letter Ensemble. The second weapon is consumed."
    case 1: "Forward Drive + Practice Thrust, both Lv8 or Lv9; claim a chest for Golden Duet. The second weapon is consumed."
    case 2: "Vinyl Arc + Shadow Verse, both Lv8 or Lv9; claim a chest for Midnight Session. The second weapon is consumed."
    case 3: "Moon Orbit + Waking Frame, both Lv8 or Lv9; claim a chest for Slow Dancing Halo. The second weapon is consumed."
    case 4: "Hearth Glow + Garden Orbit, both Lv8 or Lv9; claim a chest for Garden Rest Home. The second weapon is consumed."
    case 5: "Burning Verse + Homeward Comet, both Lv8 or Lv9; claim a chest for D-DAY Supernova. The second weapon is consumed."
    case _: ""
def recipe(category: U32,+id: U32) -> String:
  match category:
    case 0: weapon_recipe(id)
    case 8: union_recipe(id)
    case _: ""
