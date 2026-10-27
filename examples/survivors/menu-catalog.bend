# Browser/menu catalog authority. Stable IDs match the Bend simulation.
# Edit catalog rows here; content.mjs is generated from json() during web builds.
# This module is independent of the simulation so menu loading never imports game.bend.
import Base
import character-policy.bend as CP

def achievements_0() -> String: "{\"id\":\"firstblood\",\"name\":\"First Spark\",\"description\":\"Defeat 100 enemies.\",\"condition\":{\"stat\":\"kills\",\"value\":100},\"conditions\":{\"kills\":100}}"

def achievements_1() -> String: "{\"id\":\"hunter\",\"name\":\"Hunter\",\"description\":\"Defeat 1,000 enemies.\",\"condition\":{\"stat\":\"kills\",\"value\":1000},\"conditions\":{\"kills\":1000}}"

def achievements_2() -> String: "{\"id\":\"legion\",\"name\":\"Legion's Fall\",\"description\":\"Defeat 10,000 enemies.\",\"condition\":{\"stat\":\"kills\",\"value\":10000},\"conditions\":{\"kills\":10000}}"

def achievements_3() -> String: "{\"id\":\"nightmare\",\"name\":\"Nightmare's Nightmare\",\"description\":\"Defeat 50,000 enemies.\",\"condition\":{\"stat\":\"kills\",\"value\":50000},\"conditions\":{\"kills\":50000}}"

def achievements_4() -> String: "{\"id\":\"purse\",\"name\":\"Heavy Purse\",\"description\":\"Earn 1,000 gold in total.\",\"condition\":{\"stat\":\"totalgold\",\"value\":1000},\"conditions\":{\"totalgold\":1000}}"

def achievements_5() -> String: "{\"id\":\"treasury\",\"name\":\"Treasury\",\"description\":\"Earn 10,000 gold in total.\",\"condition\":{\"stat\":\"totalgold\",\"value\":10000},\"conditions\":{\"totalgold\":10000}}"

def achievements_6() -> String: "{\"id\":\"minute\",\"name\":\"Stand Firm\",\"description\":\"Survive for 60 seconds.\",\"condition\":{\"stat\":\"survive\",\"value\":60},\"conditions\":{\"survive\":60}}"

def achievements_7() -> String: "{\"id\":\"five\",\"name\":\"Halfway There\",\"description\":\"Survive for 300 seconds.\",\"condition\":{\"stat\":\"survive\",\"value\":300},\"conditions\":{\"survive\":300}}"

def achievements_8() -> String: "{\"id\":\"dawn\",\"name\":\"Until Dawn\",\"description\":\"Win a run.\",\"condition\":{\"stat\":\"wins\",\"value\":1},\"conditions\":{\"wins\":1}}"

def achievements_9() -> String: "{\"id\":\"veteran\",\"name\":\"Night Veteran\",\"description\":\"Win 10 runs.\",\"condition\":{\"stat\":\"wins\",\"value\":10},\"conditions\":{\"wins\":10}}"

def achievements_10() -> String: "{\"id\":\"evolve\",\"name\":\"Transformation\",\"description\":\"Obtain your first evolution.\",\"condition\":{\"stat\":\"evolutions\",\"value\":1},\"conditions\":{\"evolutions\":1}}"

def achievements_11() -> String: "{\"id\":\"alchemist\",\"name\":\"Weapon Alchemist\",\"description\":\"Obtain 12 evolutions.\",\"condition\":{\"stat\":\"evolutions\",\"value\":12},\"conditions\":{\"evolutions\":12}}"

def achievements_12() -> String: "{\"id\":\"level20\",\"name\":\"Awakening\",\"description\":\"Reach level 20 in a run.\",\"condition\":{\"stat\":\"levels\",\"value\":20},\"conditions\":{\"levels\":20}}"

def achievements_13() -> String: "{\"id\":\"level50\",\"name\":\"Ascension\",\"description\":\"Reach level 50 in a run.\",\"condition\":{\"stat\":\"levels\",\"value\":50},\"conditions\":{\"levels\":50}}"

def achievements_14() -> String: "{\"id\":\"heroes\",\"name\":\"Seven Together\",\"description\":\"Unlock all 7 artists.\",\"condition\":{\"stat\":\"characters\",\"value\":7},\"conditions\":{\"characters\":7}}"

def achievements_15() -> String: "{\"id\":\"worlds\",\"name\":\"Every Road\",\"description\":\"Unlock 5 stages.\",\"condition\":{\"stat\":\"stages\",\"value\":5},\"conditions\":{\"stages\":5}}"

def achievements_16() -> String: "{\"id\":\"arsenal\",\"name\":\"Night Arsenal\",\"description\":\"Use 24 weapon types.\",\"condition\":{\"stat\":\"weapons\",\"value\":24},\"conditions\":{\"weapons\":24}}"

def achievements_17() -> String: "{\"id\":\"rebirth\",\"name\":\"Against Fate\",\"description\":\"Revive during a run.\",\"condition\":{\"stat\":\"revivals\",\"value\":1},\"conditions\":{\"revivals\":1}}"

def achievements_18() -> String: "{\"id\":\"bosses\",\"name\":\"Overlord Breaker\",\"description\":\"Defeat 20 bosses.\",\"condition\":{\"stat\":\"bosskills\",\"value\":20},\"conditions\":{\"bosskills\":20}}"

def achievements_19() -> String: "{\"id\":\"champions\",\"name\":\"Seven Encores\",\"description\":\"Win with all 7 artists.\",\"condition\":{\"stat\":\"characterwins\",\"value\":7},\"conditions\":{\"characterwins\":7}}"

def achievements() -> String:
  "[" ++ achievements_0() ++ "," ++ achievements_1() ++ "," ++ achievements_2() ++ "," ++ achievements_3() ++ "," ++ achievements_4() ++ "," ++ achievements_5() ++ "," ++ achievements_6() ++ "," ++ achievements_7() ++ "," ++ achievements_8() ++ "," ++ achievements_9() ++ "," ++ achievements_10() ++ "," ++ achievements_11() ++ "," ++ achievements_12() ++ "," ++ achievements_13() ++ "," ++ achievements_14() ++ "," ++ achievements_15() ++ "," ++ achievements_16() ++ "," ++ achievements_17() ++ "," ++ achievements_18() ++ "," ++ achievements_19() ++ "]"

def arcana_0() -> String: "{\"id\":0,\"name\":\"FACE of Glass\",\"icon\":\"/\",\"description\":\"Might +35%, maximum health -30%.\"}"

def arcana_1() -> String: "{\"id\":1,\"name\":\"Street Metronome\",\"icon\":\"o\",\"description\":\"Attack cooldown -20%, area -15%.\"}"

def arcana_2() -> String: "{\"id\":2,\"name\":\"Indigo Gallery\",\"icon\":\"O\",\"description\":\"Area +35%, movement speed -15%.\"}"

def arcana_3() -> String: "{\"id\":3,\"name\":\"Duet Reflection\",\"icon\":\"Y\",\"description\":\"Projectile count +1, attack cooldown +15%.\"}"

def arcana_4() -> String: "{\"id\":4,\"name\":\"Mirror Resolve\",\"icon\":\"#\",\"description\":\"Armor +3, might -15%. Taking damage releases protective orbiting leaves, even without Leaf Orbit equipped.\",\"synergy\":{\"kind\":\"retaliation\",\"weapons\":[19],\"requiresOwned\":false}}"

def arcana_5() -> String: "{\"id\":5,\"name\":\"Unwritten Verse\",\"icon\":\"A\",\"description\":\"Experience +30%; enemy health and count +20%. Poem Fragment and Final Bow gain 20% damage, plus 5% per Jack in the Box rank.\",\"synergy\":{\"kind\":\"curseDamage\",\"weapons\":[9,11],\"passive\":14}}"

def arcana_6() -> String: "{\"id\":6,\"name\":\"Cosmic Hospitality\",\"icon\":\"+\",\"description\":\"Pickup radius +100%, gold +25%.\"}"

def arcana_7() -> String: "{\"id\":7,\"name\":\"D-DAY Ember\",\"icon\":\"!\",\"description\":\"Duration +50%, projectile speed -20%. Burns last twice as long and deal double damage per tick.\",\"synergy\":{\"kind\":\"burn\",\"weapons\":[6,17],\"durationMultiplier\":2,\"damageMultiplier\":2}}"

def arcana_8() -> String: "{\"id\":8,\"name\":\"Golden Trajectory\",\"icon\":\">\",\"description\":\"Projectile speed +50%, might +15%. Traveling projectiles ricochet from the world boundary.\",\"synergy\":{\"kind\":\"ricochet\",\"weapons\":[0,1,2,6,8,10,12,13,14,15,16,17,18,23]}}"

def arcana_9() -> String: "{\"id\":9,\"name\":\"Namjooning\",\"icon\":\"+\",\"description\":\"Regenerates 2 health per second; maximum health +25%. With Warm Hearth or Leaf Orbit equipped, kills on periodic life-steal pulses restore 1 health each.\",\"synergy\":{\"kind\":\"killHealing\",\"weapons\":[4,19],\"healthPerKill\":2}}"

def arcana_10() -> String: "{\"id\":10,\"name\":\"Hopeful Footwork\",\"icon\":\">\",\"description\":\"Movement speed +30%, healing received +30%.\"}"

def arcana_11() -> String: "{\"id\":11,\"name\":\"Composition of Wind\",\"icon\":\"~\",\"description\":\"Knockback +75%, area +15%. Vortex pull strength increases from 3 to 7.\",\"synergy\":{\"kind\":\"pull\",\"weapons\":[20],\"baseStrength\":3,\"strength\":7}}"

def arcana() -> String:
  "[" ++ arcana_0() ++ "," ++ arcana_1() ++ "," ++ arcana_2() ++ "," ++ arcana_3() ++ "," ++ arcana_4() ++ "," ++ arcana_5() ++ "," ++ arcana_6() ++ "," ++ arcana_7() ++ "," ++ arcana_8() ++ "," ++ arcana_9() ++ "," ++ arcana_10() ++ "," ++ arcana_11() ++ "]"

def starter(id: U32) -> U32: CP.starter(id)

def characters_0() -> String: "{\"id\":0,\"name\":\"RM\",\"title\":\"Order in Chaos\",\"description\":\"Pulling ink fields organize the crowd. Pickup radius +50%.\",\"weapon\":" ++ U32.show(starter(0)) ++ ",\"color\":\"#7b98dc\",\"cost\":0}"

def characters_1() -> String: "{\"id\":1,\"name\":\"Jin\",\"title\":\"Warm Astronaut\",\"description\":\"An orbiting Home Star fires homing letters. Regenerates 1 health per second.\",\"weapon\":" ++ U32.show(starter(1)) ++ ",\"color\":\"#f6ddba\",\"cost\":250,\"condition\":{\"stat\":\"kills\",\"value\":100},\"hint\":\"Defeat 100 enemies across your runs.\"}"

def characters_2() -> String: "{\"id\":2,\"name\":\"SUGA\",\"title\":\"Quiet Storm\",\"description\":\"Delayed sound charges release a heavy burst. Might +20%.\",\"weapon\":" ++ U32.show(starter(2)) ++ ",\"color\":\"#e65e64\",\"cost\":500,\"condition\":{\"stat\":\"survive\",\"value\":120},\"hint\":\"Survive for 2 minutes in a single run.\"}"

def characters_3() -> String: "{\"id\":3,\"name\":\"j-hope\",\"title\":\"Street Choreographer\",\"description\":\"Leave delayed beat pulses for pursuers. Movement speed +15%.\",\"weapon\":" ++ U32.show(starter(3)) ++ ",\"color\":\"#a5e38b\",\"cost\":750,\"condition\":{\"stat\":\"evolutions\",\"value\":1},\"hint\":\"Obtain a weapon evolution.\"}"

def characters_4() -> String: "{\"id\":4,\"name\":\"Jimin\",\"title\":\"Mirror Dancer\",\"description\":\"A mirrored fan cuts outward and returns. Armor +1.\",\"weapon\":" ++ U32.show(starter(4)) ++ ",\"color\":\"#f2b5d5\",\"cost\":1000,\"condition\":{\"stat\":\"bosskills\",\"value\":2},\"hint\":\"Defeat 2 bosses across your runs.\"}"

def characters_5() -> String: "{\"id\":5,\"name\":\"V\",\"title\":\"Dream Wanderer\",\"description\":\"Dream frames fire in several directions. Weapon cooldown -10%.\",\"weapon\":" ++ U32.show(starter(5)) ++ ",\"color\":\"#c58da4\",\"cost\":1500,\"condition\":{\"stat\":\"wins\",\"value\":1},\"hint\":\"Win a run.\"}"

def characters_6() -> String: "{\"id\":6,\"name\":\"Jung Kook\",\"title\":\"Golden All-rounder\",\"description\":\"Fast gold streaks follow your movement. Might +10%; maximum health +25%.\",\"weapon\":" ++ U32.show(starter(6)) ++ ",\"color\":\"#f4c861\",\"cost\":2200,\"condition\":{\"stat\":\"kills\",\"value\":3000},\"hint\":\"Defeat 3,000 enemies across your runs.\"}"

def characters() -> String:
  "[" ++ characters_0() ++ "," ++ characters_1() ++ "," ++ characters_2() ++ "," ++ characters_3() ++ "," ++ characters_4() ++ "," ++ characters_5() ++ "," ++ characters_6() ++ "]"

def collections() -> String: "{\"weapons\":[{\"id\":0,\"name\":\"Starlight Letter\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":0,\"value\":1}},{\"id\":1,\"name\":\"Golden Rush\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":1,\"value\":1}},{\"id\":2,\"name\":\"Vinyl Arc\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":2,\"value\":1}},{\"id\":3,\"name\":\"Moon Orbit\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":3,\"value\":1}},{\"id\":4,\"name\":\"Warm Hearth\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":4,\"value\":1}},{\"id\":5,\"name\":\"Spotlight Snap\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":5,\"value\":1}},{\"id\":6,\"name\":\"Red Verse\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":6,\"value\":1}},{\"id\":7,\"name\":\"Indigo Rain\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":7,\"value\":1}},{\"id\":8,\"name\":\"Mirror Fan\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":8,\"value\":1}},{\"id\":9,\"name\":\"Poem Fragment\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":9,\"value\":1}},{\"id\":10,\"name\":\"Quiet Reflection\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":10,\"value\":1}},{\"id\":11,\"name\":\"Final Bow\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":11,\"value\":1}},{\"id\":12,\"name\":\"Ribbon Sweep\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":12,\"value\":1}},{\"id\":13,\"name\":\"Practice Line\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":13,\"value\":1}},{\"id\":14,\"name\":\"D-DAY Release\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":14,\"value\":1}},{\"id\":15,\"name\":\"Shadow Verse\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":15,\"value\":1}},{\"id\":16,\"name\":\"SHOOKY Mischief\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":16,\"value\":1}},{\"id\":17,\"name\":\"Astronaut Comet\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":17,\"value\":1}},{\"id\":18,\"name\":\"Stage Beam\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":18,\"value\":1}},{\"id\":19,\"name\":\"Leaf Orbit\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":19,\"value\":1}},{\"id\":20,\"name\":\"Indigo Composition\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":20,\"value\":1}},{\"id\":21,\"name\":\"Home Star\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":21,\"value\":1}},{\"id\":22,\"name\":\"Street Beat\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":22,\"value\":1}},{\"id\":23,\"name\":\"Dream Frame\",\"condition\":{\"stat\":\"weaponUsed\",\"id\":23,\"value\":1}}],\"evolutions\":[{\"id\":0,\"name\":\"Constellation Letter\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":0,\"value\":1}},{\"id\":1,\"name\":\"Golden Overdrive\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":1,\"value\":1}},{\"id\":2,\"name\":\"Midnight Rotation\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":2,\"value\":1}},{\"id\":3,\"name\":\"Astronaut Halo\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":3,\"value\":1}},{\"id\":4,\"name\":\"Homecoming Glow\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":4,\"value\":1}},{\"id\":5,\"name\":\"Stage Thunder\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":5,\"value\":1}},{\"id\":6,\"name\":\"Agust Inferno\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":6,\"value\":1}},{\"id\":7,\"name\":\"Namjooning Rain\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":7,\"value\":1}},{\"id\":8,\"name\":\"MUSE Reflection\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":8,\"value\":1}},{\"id\":9,\"name\":\"Indigo Manuscript\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":9,\"value\":1}},{\"id\":10,\"name\":\"FACE Stillness\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":10,\"value\":1}},{\"id\":11,\"name\":\"Encore Sky\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":11,\"value\":1}},{\"id\":12,\"name\":\"Silk Crescendo\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":12,\"value\":1}},{\"id\":13,\"name\":\"Perfect Take\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":13,\"value\":1}},{\"id\":14,\"name\":\"Agust Storm\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":14,\"value\":1}},{\"id\":15,\"name\":\"Daechwita Echo\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":15,\"value\":1}},{\"id\":16,\"name\":\"Cookie Chorus\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":16,\"value\":1}},{\"id\":17,\"name\":\"Homeward Meteor\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":17,\"value\":1}},{\"id\":18,\"name\":\"Golden Spotlight\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":18,\"value\":1}},{\"id\":19,\"name\":\"Museum Garden\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":19,\"value\":1}},{\"id\":20,\"name\":\"Order in Chaos\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":20,\"value\":1}},{\"id\":21,\"name\":\"RJ Constellation\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":21,\"value\":1}},{\"id\":22,\"name\":\"HOPE Block Party\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":22,\"value\":1}},{\"id\":23,\"name\":\"TATA Dreamscape\",\"condition\":{\"stat\":\"weaponEvolved\",\"id\":23,\"value\":1}}],\"enemies\":[{\"id\":0,\"name\":\"Bone Wanderer\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":0,\"value\":1}},{\"id\":1,\"name\":\"Midnight Bat\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":1,\"value\":1}},{\"id\":2,\"name\":\"Hungry Corpse\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":2,\"value\":1}},{\"id\":3,\"name\":\"Marsh Slime\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":3,\"value\":1}},{\"id\":4,\"name\":\"Wild Wolf\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":4,\"value\":1}},{\"id\":5,\"name\":\"Cursed Knight\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":5,\"value\":1}},{\"id\":6,\"name\":\"Plague Rat\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":6,\"value\":1}},{\"id\":7,\"name\":\"Wandering Spirit\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":7,\"value\":1}},{\"id\":8,\"name\":\"Ash Spider\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":8,\"value\":1}},{\"id\":9,\"name\":\"Bone Archer\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":9,\"value\":1}},{\"id\":10,\"name\":\"Blood Cultist\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":10,\"value\":1}},{\"id\":11,\"name\":\"Mimic\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":11,\"value\":1}},{\"id\":12,\"name\":\"Ice Guard\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":12,\"value\":1}},{\"id\":13,\"name\":\"Fire Imp\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":13,\"value\":1}},{\"id\":14,\"name\":\"Venom Toad\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":14,\"value\":1}},{\"id\":15,\"name\":\"Twilight Harpy\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":15,\"value\":1}},{\"id\":16,\"name\":\"Grave Golem\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":16,\"value\":1}},{\"id\":17,\"name\":\"Scarab Swarm\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":17,\"value\":1}},{\"id\":18,\"name\":\"Ancient Treant\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":18,\"value\":1}},{\"id\":19,\"name\":\"Mist Reaper\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":19,\"value\":1}},{\"id\":20,\"name\":\"Graveyard Warden\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":20,\"value\":1}},{\"id\":21,\"name\":\"Abyssal Librarian\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":21,\"value\":1}},{\"id\":22,\"name\":\"Marsh Queen\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":22,\"value\":1}},{\"id\":23,\"name\":\"Frost Sovereign\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":23,\"value\":1}},{\"id\":24,\"name\":\"Ash Prince\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":24,\"value\":1}},{\"id\":25,\"name\":\"Bone Colossus\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":25,\"value\":1}},{\"id\":26,\"name\":\"Swarm Matriarch\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":26,\"value\":1}},{\"id\":27,\"name\":\"Star Devourer\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":27,\"value\":1}},{\"id\":28,\"name\":\"Last Door Guardian\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":28,\"value\":1}},{\"id\":29,\"name\":\"Night Incarnate\",\"condition\":{\"stat\":\"enemyKilled\",\"id\":29,\"value\":1}},{\"id\":30,\"name\":\"Dawn Reaper\",\"condition\":{\"stat\":\"wins\",\"value\":1}}]}"

def enemies_0() -> String: "{\"id\":0,\"name\":\"Bone Wanderer\",\"kind\":\"skeleton\",\"boss\":false}"

def enemies_1() -> String: "{\"id\":1,\"name\":\"Midnight Bat\",\"kind\":\"bat\",\"boss\":false}"

def enemies_2() -> String: "{\"id\":2,\"name\":\"Hungry Corpse\",\"kind\":\"zombie\",\"boss\":false}"

def enemies_3() -> String: "{\"id\":3,\"name\":\"Marsh Slime\",\"kind\":\"slime\",\"boss\":false}"

def enemies_4() -> String: "{\"id\":4,\"name\":\"Wild Wolf\",\"kind\":\"wolf\",\"boss\":false}"

def enemies_5() -> String: "{\"id\":5,\"name\":\"Cursed Knight\",\"kind\":\"knight\",\"boss\":false}"

def enemies_6() -> String: "{\"id\":6,\"name\":\"Plague Rat\",\"kind\":\"rat\",\"boss\":false}"

def enemies_7() -> String: "{\"id\":7,\"name\":\"Wandering Spirit\",\"kind\":\"ghost\",\"boss\":false}"

def enemies_8() -> String: "{\"id\":8,\"name\":\"Ash Spider\",\"kind\":\"spider\",\"boss\":false}"

def enemies_9() -> String: "{\"id\":9,\"name\":\"Bone Archer\",\"kind\":\"archer\",\"boss\":false}"

def enemies_10() -> String: "{\"id\":10,\"name\":\"Blood Cultist\",\"kind\":\"cultist\",\"boss\":false}"

def enemies_11() -> String: "{\"id\":11,\"name\":\"Mimic\",\"kind\":\"mimic\",\"boss\":false}"

def enemies_12() -> String: "{\"id\":12,\"name\":\"Ice Guard\",\"kind\":\"iceguard\",\"boss\":false}"

def enemies_13() -> String: "{\"id\":13,\"name\":\"Fire Imp\",\"kind\":\"imp\",\"boss\":false}"

def enemies_14() -> String: "{\"id\":14,\"name\":\"Venom Toad\",\"kind\":\"toad\",\"boss\":false}"

def enemies_15() -> String: "{\"id\":15,\"name\":\"Twilight Harpy\",\"kind\":\"harpy\",\"boss\":false}"

def enemies_16() -> String: "{\"id\":16,\"name\":\"Grave Golem\",\"kind\":\"golem\",\"boss\":false}"

def enemies_17() -> String: "{\"id\":17,\"name\":\"Scarab Swarm\",\"kind\":\"swarm\",\"boss\":false}"

def enemies_18() -> String: "{\"id\":18,\"name\":\"Ancient Treant\",\"kind\":\"ent\",\"boss\":false}"

def enemies_19() -> String: "{\"id\":19,\"name\":\"Mist Reaper\",\"kind\":\"reaper\",\"boss\":false}"

def enemies_20() -> String: "{\"id\":20,\"name\":\"Graveyard Warden\",\"kind\":\"boss\",\"boss\":true}"

def enemies_21() -> String: "{\"id\":21,\"name\":\"Abyssal Librarian\",\"kind\":\"boss\",\"boss\":true}"

def enemies_22() -> String: "{\"id\":22,\"name\":\"Marsh Queen\",\"kind\":\"boss\",\"boss\":true}"

def enemies_23() -> String: "{\"id\":23,\"name\":\"Frost Sovereign\",\"kind\":\"boss\",\"boss\":true}"

def enemies_24() -> String: "{\"id\":24,\"name\":\"Ash Prince\",\"kind\":\"boss\",\"boss\":true}"

def enemies_25() -> String: "{\"id\":25,\"name\":\"Bone Colossus\",\"kind\":\"boss\",\"boss\":true}"

def enemies_26() -> String: "{\"id\":26,\"name\":\"Swarm Matriarch\",\"kind\":\"boss\",\"boss\":true}"

def enemies_27() -> String: "{\"id\":27,\"name\":\"Star Devourer\",\"kind\":\"boss\",\"boss\":true}"

def enemies_28() -> String: "{\"id\":28,\"name\":\"Last Door Guardian\",\"kind\":\"boss\",\"boss\":true}"

def enemies_29() -> String: "{\"id\":29,\"name\":\"Night Incarnate\",\"kind\":\"boss\",\"boss\":true}"

def enemies_30() -> String: "{\"id\":30,\"name\":\"Dawn Reaper\",\"kind\":\"reaper\",\"boss\":true,\"description\":\"The dawn hunter ignores crowd control and deals lethal contact damage. Endless excludes it.\"}"

def enemies() -> String:
  "[" ++ enemies_0() ++ "," ++ enemies_1() ++ "," ++ enemies_2() ++ "," ++ enemies_3() ++ "," ++ enemies_4() ++ "," ++ enemies_5() ++ "," ++ enemies_6() ++ "," ++ enemies_7() ++ "," ++ enemies_8() ++ "," ++ enemies_9() ++ "," ++ enemies_10() ++ "," ++ enemies_11() ++ "," ++ enemies_12() ++ "," ++ enemies_13() ++ "," ++ enemies_14() ++ "," ++ enemies_15() ++ "," ++ enemies_16() ++ "," ++ enemies_17() ++ "," ++ enemies_18() ++ "," ++ enemies_19() ++ "," ++ enemies_20() ++ "," ++ enemies_21() ++ "," ++ enemies_22() ++ "," ++ enemies_23() ++ "," ++ enemies_24() ++ "," ++ enemies_25() ++ "," ++ enemies_26() ++ "," ++ enemies_27() ++ "," ++ enemies_28() ++ "," ++ enemies_29() ++ "," ++ enemies_30() ++ "]"

def meta_upgrades_0() -> String: "{\"id\":0,\"key\":\"might\",\"name\":\"Daily Practice\",\"costBase\":150,\"cost\":150,\"maxLevel\":5,\"max\":5,\"description\":\"Damage +5% per rank.\"}"

def meta_upgrades_1() -> String: "{\"id\":1,\"key\":\"maxhealth\",\"name\":\"Stamina Training\",\"costBase\":120,\"cost\":120,\"maxLevel\":5,\"max\":5,\"description\":\"Maximum health +10% per rank.\"}"

def meta_upgrades_2() -> String: "{\"id\":2,\"key\":\"regen\",\"name\":\"After-show Rest\",\"costBase\":180,\"cost\":180,\"maxLevel\":5,\"max\":5,\"description\":\"Regenerates 1 health per second per rank.\"}"

def meta_upgrades_3() -> String: "{\"id\":3,\"key\":\"armor\",\"name\":\"Stage Resolve\",\"costBase\":250,\"cost\":250,\"maxLevel\":3,\"max\":3,\"description\":\"Armor +1 per rank.\"}"

def meta_upgrades_4() -> String: "{\"id\":4,\"key\":\"cooldown\",\"name\":\"Metronome Study\",\"costBase\":300,\"cost\":300,\"maxLevel\":5,\"max\":5,\"description\":\"Attack cooldown -3% per rank.\"}"

def meta_upgrades_5() -> String: "{\"id\":5,\"key\":\"speed\",\"name\":\"Footwork Practice\",\"costBase\":100,\"cost\":100,\"maxLevel\":5,\"max\":5,\"description\":\"Movement speed +5% per rank.\"}"

def meta_upgrades_6() -> String: "{\"id\":6,\"key\":\"magnet\",\"name\":\"Museum Attention\",\"costBase\":120,\"cost\":120,\"maxLevel\":5,\"max\":5,\"description\":\"Pickup radius +15% per rank.\"}"

def meta_upgrades_7() -> String: "{\"id\":7,\"key\":\"growth\",\"name\":\"Poetry Journal\",\"costBase\":250,\"cost\":250,\"maxLevel\":5,\"max\":5,\"description\":\"Experience +5% per rank.\"}"

def meta_upgrades_8() -> String: "{\"id\":8,\"key\":\"greed\",\"name\":\"Golden Keepsake\",\"costBase\":150,\"cost\":150,\"maxLevel\":5,\"max\":5,\"description\":\"Gold +10% per rank.\"}"

def meta_upgrades_9() -> String: "{\"id\":9,\"key\":\"revival\",\"name\":\"Encore Promise\",\"costBase\":1500,\"cost\":1500,\"maxLevel\":2,\"max\":2,\"description\":\"One additional revival per rank.\"}"

def meta_upgrades() -> String:
  "[" ++ meta_upgrades_0() ++ "," ++ meta_upgrades_1() ++ "," ++ meta_upgrades_2() ++ "," ++ meta_upgrades_3() ++ "," ++ meta_upgrades_4() ++ "," ++ meta_upgrades_5() ++ "," ++ meta_upgrades_6() ++ "," ++ meta_upgrades_7() ++ "," ++ meta_upgrades_8() ++ "," ++ meta_upgrades_9() ++ "]"

def passives_0() -> String: "{\"id\":0,\"name\":\"GOLDEN Drive\",\"icon\":\"+\",\"description\":\"All weapon damage +10% per rank.\",\"maxLevel\":5}"

def passives_1() -> String: "{\"id\":1,\"name\":\"Beat Clock\",\"icon\":\"o\",\"description\":\"Attack cooldown -7% per rank.\",\"maxLevel\":5}"

def passives_2() -> String: "{\"id\":2,\"name\":\"Gallery Lens\",\"icon\":\"O\",\"description\":\"Weapon and effect area +10% per rank.\",\"maxLevel\":5}"

def passives_3() -> String: "{\"id\":3,\"name\":\"Long Encore\",\"icon\":\"~\",\"description\":\"Weapon duration +15% per rank.\",\"maxLevel\":5}"

def passives_4() -> String: "{\"id\":4,\"name\":\"Harmony Split\",\"icon\":\"Y\",\"description\":\"One additional projectile per rank.\",\"maxLevel\":5}"

def passives_5() -> String: "{\"id\":5,\"name\":\"Dance Sneakers\",\"icon\":\">\",\"description\":\"Movement speed +10% per rank.\",\"maxLevel\":5}"

def passives_6() -> String: "{\"id\":6,\"name\":\"Mirror Guard\",\"icon\":\"#\",\"description\":\"Reduces incoming damage by 1 per rank.\",\"maxLevel\":5}"

def passives_7() -> String: "{\"id\":7,\"name\":\"Warm Heart\",\"icon\":\"+\",\"description\":\"Maximum health +20% per rank.\",\"maxLevel\":5}"

def passives_8() -> String: "{\"id\":8,\"name\":\"KOYA Focus\",\"icon\":\"O\",\"description\":\"Experience pickup radius +25% per rank.\",\"maxLevel\":5}"

def passives_9() -> String: "{\"id\":9,\"name\":\"Lyric Notebook\",\"icon\":\"A\",\"description\":\"Experience gained +10% per rank.\",\"maxLevel\":5}"

def passives_10() -> String: "{\"id\":10,\"name\":\"TATA Curiosity\",\"icon\":\"?\",\"description\":\"Luck +10% per rank, improving normal enemy gold and healing drops.\",\"maxLevel\":5}"

def passives_11() -> String: "{\"id\":11,\"name\":\"RJ Comfort\",\"icon\":\"+\",\"description\":\"Regenerates 1 health per second per rank.\",\"maxLevel\":5}"

def passives_12() -> String: "{\"id\":12,\"name\":\"Golden Tempo\",\"icon\":\">\",\"description\":\"Projectile speed +15% per rank.\",\"maxLevel\":5}"

def passives_13() -> String: "{\"id\":13,\"name\":\"Second Encore\",\"icon\":\"8\",\"description\":\"One additional full-health revival per rank.\",\"maxLevel\":5}"

def passives_14() -> String: "{\"id\":14,\"name\":\"Jack in the Box\",\"icon\":\"!\",\"description\":\"Enemy health and count +10% per rank; experience and gold +10% per rank.\",\"maxLevel\":5}"

def passives_15() -> String: "{\"id\":15,\"name\":\"Platinum Record\",\"icon\":\"O\",\"description\":\"Gold gained +15% per rank.\",\"maxLevel\":5}"

def passives_16() -> String: "{\"id\":16,\"name\":\"Bass Pulse\",\"icon\":\">\",\"description\":\"Enemy knockback +15% per rank.\",\"maxLevel\":5}"

def passives_17() -> String: "{\"id\":17,\"name\":\"Home Cooking\",\"icon\":\"+\",\"description\":\"Healing from pickups and regeneration +20% per rank.\",\"maxLevel\":5}"

def passives() -> String:
  "[" ++ passives_0() ++ "," ++ passives_1() ++ "," ++ passives_2() ++ "," ++ passives_3() ++ "," ++ passives_4() ++ "," ++ passives_5() ++ "," ++ passives_6() ++ "," ++ passives_7() ++ "," ++ passives_8() ++ "," ++ passives_9() ++ "," ++ passives_10() ++ "," ++ passives_11() ++ "," ++ passives_12() ++ "," ++ passives_13() ++ "," ++ passives_14() ++ "," ++ passives_15() ++ "," ++ passives_16() ++ "," ++ passives_17() ++ "]"

def run_modes_0() -> String: "{\"id\":0,\"key\":\"standard\",\"name\":\"Standard\",\"description\":\"Survive ten minutes and defeat the night.\",\"durationLabel\":\"10 minutes\"}"

def run_modes_1() -> String: "{\"id\":1,\"key\":\"inverse\",\"name\":\"Inverse\",\"description\":\"A harsher night with stronger enemies and greater rewards.\",\"condition\":{\"stat\":\"levels\",\"value\":20},\"hint\":\"Reach level 20 in a single run.\",\"durationLabel\":\"10 minutes\"}"

def run_modes_2() -> String: "{\"id\":2,\"key\":\"endless\",\"name\":\"Endless\",\"description\":\"The horde keeps growing beyond the dawn. Survive as long as you can.\",\"condition\":{\"stat\":\"wins\",\"value\":1},\"hint\":\"Win a run.\",\"durationLabel\":\"No time limit\"}"

def run_modes_3() -> String: "{\"id\":3,\"key\":\"trial\",\"name\":\"Trial\",\"description\":\"A five-minute challenge with accelerated waves. Permanent upgrades are disabled.\",\"condition\":{\"stat\":\"bosskills\",\"value\":3},\"hint\":\"Defeat 3 bosses across your runs.\",\"durationLabel\":\"5 minutes\"}"

def run_modes() -> String:
  "[" ++ run_modes_0() ++ "," ++ run_modes_1() ++ "," ++ run_modes_2() ++ "," ++ run_modes_3() ++ "]"

def stages_0() -> String: "{\"id\":0,\"key\":\"graveyard\",\"name\":\"Forgotten Graveyard\",\"description\":\"An open field beneath the moon. The skeletal horde never lets you rest.\",\"duration\":600,\"cost\":0,\"palette\":[\"#101725\",\"#26374a\",\"#86baaa\"]}"

def stages_1() -> String: "{\"id\":1,\"key\":\"library\",\"name\":\"Midnight Library\",\"description\":\"Forbidden shelves and relentless pursuers. Keep an escape route open.\",\"duration\":600,\"cost\":500,\"palette\":[\"#201925\",\"#4a3448\",\"#d9b286\"],\"condition\":{\"stat\":\"survive\",\"value\":180},\"hint\":\"Survive for 3 minutes in a single run.\"}"

def stages_2() -> String: "{\"id\":2,\"key\":\"marsh\",\"name\":\"Wisp Marsh\",\"description\":\"Ancient wetlands and venomous creatures. Keep moving to survive.\",\"duration\":600,\"cost\":1000,\"palette\":[\"#10241e\",\"#284936\",\"#b7c571\"],\"condition\":{\"stat\":\"levels\",\"value\":20},\"hint\":\"Reach level 20 in a single run.\"}"

def stages_3() -> String: "{\"id\":3,\"key\":\"frostpeak\",\"name\":\"Frozen Pass\",\"description\":\"A cold expanse beneath the charge of swift northern beasts.\",\"duration\":600,\"cost\":1800,\"palette\":[\"#172433\",\"#365166\",\"#a5e8f2\"],\"condition\":{\"stat\":\"bosskills\",\"value\":5},\"hint\":\"Defeat 5 bosses across your runs.\"}"

def stages_4() -> String: "{\"id\":4,\"key\":\"inferno\",\"name\":\"Infernal Maw\",\"description\":\"The final frontier: furious waves and ancient overlords.\",\"duration\":600,\"cost\":2800,\"palette\":[\"#2d141b\",\"#623034\",\"#f4ad76\"],\"condition\":{\"stat\":\"wins\",\"value\":2},\"hint\":\"Win 2 runs.\"}"

def stages() -> String:
  "[" ++ stages_0() ++ "," ++ stages_1() ++ "," ++ stages_2() ++ "," ++ stages_3() ++ "," ++ stages_4() ++ "]"

def stage_relics_0() -> String: "{\"id\":0,\"name\":\"Silk Spool\",\"description\":\"Find this relic in Forgotten Graveyard to unlock Ribbon Sweep for future runs.\",\"weapon\":12,\"x\":10800,\"y\":7200}"

def stage_relics_1() -> String: "{\"id\":1,\"name\":\"Golden Filament\",\"description\":\"Find this relic in Midnight Library to unlock Stage Beam for future runs.\",\"weapon\":18,\"x\":7200,\"y\":3600}"

def stage_relics_2() -> String: "{\"id\":2,\"name\":\"SHOOKY Crumb\",\"description\":\"Find this relic in Wisp Marsh to unlock SHOOKY Mischief for future runs.\",\"weapon\":16,\"x\":3600,\"y\":7200}"

def stage_relics_3() -> String: "{\"id\":3,\"name\":\"Street Cassette\",\"description\":\"Find this relic in Frozen Pass to unlock Street Beat for future runs.\",\"weapon\":22,\"x\":7200,\"y\":10800}"

def stage_relics_4() -> String: "{\"id\":4,\"name\":\"Astronaut Map\",\"description\":\"Find this relic in Infernal Maw to unlock Astronaut Comet for future runs.\",\"weapon\":17,\"x\":10080,\"y\":9360}"

def stage_relics() -> String:
  "[" ++ stage_relics_0() ++ "," ++ stage_relics_1() ++ "," ++ stage_relics_2() ++ "," ++ stage_relics_3() ++ "," ++ stage_relics_4() ++ "]"

def unions_0() -> String: "{\"id\":0,\"name\":\"Letter Ensemble\",\"icon\":\"*\",\"color\":\"#bedbff\",\"weapons\":[0,5],\"description\":\"Homing letters and targeted spotlights join pursuing cookie sparks.\",\"thirdWeapon\":16}"

def unions_1() -> String: "{\"id\":1,\"name\":\"Golden Duet\",\"icon\":\">\",\"color\":\"#f4c861\",\"weapons\":[1,13],\"description\":\"Fast gold streaks and practice thrusts join outward dream frames.\",\"thirdWeapon\":23}"

def unions_2() -> String: "{\"id\":2,\"name\":\"Midnight Session\",\"icon\":\"O\",\"color\":\"#b99970\",\"weapons\":[2,15],\"description\":\"Arcing records and radial sound blades join orbiting moon discs.\",\"thirdWeapon\":3}"

def unions_3() -> String: "{\"id\":3,\"name\":\"Slow Dancing Halo\",\"icon\":\"o\",\"color\":\"#c58da4\",\"weapons\":[3,23],\"description\":\"Orbiting moons and outward dream frames join piercing stage beams.\",\"thirdWeapon\":18}"

def unions_4() -> String: "{\"id\":4,\"name\":\"Namjooning Home\",\"icon\":\"+\",\"color\":\"#94b89a\",\"weapons\":[4,19],\"description\":\"A warm aura and orbiting leaves join pulling ink fields.\",\"thirdWeapon\":20}"

def unions_5() -> String: "{\"id\":5,\"name\":\"D-DAY Supernova\",\"icon\":\"!\",\"color\":\"#e65e64\",\"weapons\":[6,17],\"description\":\"Burning verses and falling comets join delayed sound explosions.\",\"thirdWeapon\":14}"

def unions() -> String:
  "[" ++ unions_0() ++ "," ++ unions_1() ++ "," ++ unions_2() ++ "," ++ unions_3() ++ "," ++ unions_4() ++ "," ++ unions_5() ++ "]"

def weapons_0() -> String: "{\"id\":0,\"name\":\"Starlight Letter\",\"evolvedName\":\"Constellation Letter\",\"icon\":\"*\",\"color\":\"#bedbff\",\"description\":\"Homing letters seek the nearest enemy.\",\"evolvedDescription\":\"Starlight Letter alternates with Spotlight Snap. Damage +120%; area +35%.\",\"passive\":1,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":5}"

def weapons_1() -> String: "{\"id\":1,\"name\":\"Golden Rush\",\"evolvedName\":\"Golden Overdrive\",\"icon\":\">\",\"color\":\"#f4c861\",\"description\":\"Fast gold streaks fire in your movement direction.\",\"evolvedDescription\":\"Golden Rush alternates with Practice Line. Damage +120%; area +35%.\",\"passive\":12,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":13}"

def weapons_2() -> String: "{\"id\":2,\"name\":\"Vinyl Arc\",\"evolvedName\":\"Midnight Rotation\",\"icon\":\"O\",\"color\":\"#b99970\",\"description\":\"Heavy records arc through approaching enemies.\",\"evolvedDescription\":\"Vinyl Arc alternates with Shadow Verse. Damage +120%; area +35%.\",\"passive\":2,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":15}"

def weapons_3() -> String: "{\"id\":3,\"name\":\"Moon Orbit\",\"evolvedName\":\"Astronaut Halo\",\"icon\":\"o\",\"color\":\"#d8d1fa\",\"description\":\"Moon discs orbit you and strike nearby enemies.\",\"evolvedDescription\":\"Moon Orbit alternates with Dream Frame. Damage +120%; area +35%.\",\"passive\":4,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":23}"

def weapons_4() -> String: "{\"id\":4,\"name\":\"Warm Hearth\",\"evolvedName\":\"Homecoming Glow\",\"icon\":\"+\",\"color\":\"#ffe5ba\",\"description\":\"A warm close aura burns approaching enemies.\",\"evolvedDescription\":\"Warm Hearth alternates with Leaf Orbit. Damage +120%; area +35%.\",\"passive\":11,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":19}"

def weapons_5() -> String: "{\"id\":5,\"name\":\"Spotlight Snap\",\"evolvedName\":\"Stage Thunder\",\"icon\":\"!\",\"color\":\"#d2afff\",\"description\":\"Targeted spotlights strike enemies across the arena.\",\"evolvedDescription\":\"Spotlight Snap alternates with Starlight Letter. Damage +120%; area +35%.\",\"passive\":4,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":0}"

def weapons_6() -> String: "{\"id\":6,\"name\":\"Red Verse\",\"evolvedName\":\"Agust Inferno\",\"icon\":\"*\",\"color\":\"#ed6972\",\"description\":\"Burning verses pierce enemy formations.\",\"evolvedDescription\":\"Red Verse alternates with Astronaut Comet. Damage +120%; area +35%.\",\"passive\":0,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":17}"

def weapons_7() -> String: "{\"id\":7,\"name\":\"Indigo Rain\",\"evolvedName\":\"Namjooning Rain\",\"icon\":\"~\",\"color\":\"#86adc9\",\"description\":\"Ink rain leaves damaging pools at selected locations.\",\"evolvedDescription\":\"Indigo Rain alternates with Indigo Composition. Damage +120%; area +35%.\",\"passive\":3,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":20}"

def weapons_8() -> String: "{\"id\":8,\"name\":\"Mirror Fan\",\"evolvedName\":\"MUSE Reflection\",\"icon\":\"/\",\"color\":\"#f2b5d5\",\"description\":\"A mirrored fan flies out and returns through pursuers.\",\"evolvedDescription\":\"Mirror Fan alternates with Poem Fragment. Damage +120%; area +35%.\",\"passive\":10,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":9}"

def weapons_9() -> String: "{\"id\":9,\"name\":\"Poem Fragment\",\"evolvedName\":\"Indigo Manuscript\",\"icon\":\"A\",\"color\":\"#96a9e5\",\"description\":\"Fragments of a poem appear around you as damaging fields.\",\"evolvedDescription\":\"Poem Fragment alternates with Dream Frame. Damage +120%; area +35%.\",\"passive\":3,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":23}"

def weapons_10() -> String: "{\"id\":10,\"name\":\"Quiet Reflection\",\"evolvedName\":\"FACE Stillness\",\"icon\":\"|\",\"color\":\"#c2e7ed\",\"description\":\"Aimed mirror shards slow approaching enemies.\",\"evolvedDescription\":\"Quiet Reflection alternates with Spotlight Snap. Damage +120%; area +35%.\",\"passive\":1,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":5}"

def weapons_11() -> String: "{\"id\":11,\"name\":\"Final Bow\",\"evolvedName\":\"Encore Sky\",\"icon\":\"*\",\"color\":\"#f9e9af\",\"description\":\"An infrequent stage flash strikes every visible enemy.\",\"evolvedDescription\":\"Final Bow alternates with Astronaut Comet. Damage +120%; area +35%.\",\"passive\":9,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":17}"

def weapons_12() -> String: "{\"id\":12,\"name\":\"Ribbon Sweep\",\"evolvedName\":\"Silk Crescendo\",\"icon\":\"~\",\"color\":\"#eaa5bc\",\"description\":\"A broad ribbon strike sweeps the ground ahead.\",\"evolvedDescription\":\"Ribbon Sweep alternates with Warm Hearth. Damage +120%; area +35%.\",\"passive\":7,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":4}"

def weapons_13() -> String: "{\"id\":13,\"name\":\"Practice Line\",\"evolvedName\":\"Perfect Take\",\"icon\":\">\",\"color\":\"#f1d894\",\"description\":\"Long gold thrusts strike along your movement direction.\",\"evolvedDescription\":\"Practice Line alternates with Mirror Fan. Damage +120%; area +35%.\",\"passive\":12,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":8}"

def weapons_14() -> String: "{\"id\":14,\"name\":\"D-DAY Release\",\"evolvedName\":\"Agust Storm\",\"icon\":\"!\",\"color\":\"#e65e64\",\"description\":\"A thrown sound charge detonates after a delay and damages an area.\",\"evolvedDescription\":\"D-DAY Release alternates with Astronaut Comet. Damage +120%; area +35%.\",\"passive\":2,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":17}"

def weapons_15() -> String: "{\"id\":15,\"name\":\"Shadow Verse\",\"evolvedName\":\"Daechwita Echo\",\"icon\":\"/\",\"color\":\"#c3b5d6\",\"description\":\"Heavy radial sound blades slice through enemy formations.\",\"evolvedDescription\":\"Shadow Verse alternates with Vinyl Arc. Damage +120%; area +35%.\",\"passive\":0,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":2}"

def weapons_16() -> String: "{\"id\":16,\"name\":\"SHOOKY Mischief\",\"evolvedName\":\"Cookie Chorus\",\"icon\":\"o\",\"color\":\"#d0a373\",\"description\":\"Homing cookie sparks chase nearby enemies.\",\"evolvedDescription\":\"SHOOKY Mischief alternates with Red Verse. Damage +120%; area +35%.\",\"passive\":4,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":6}"

def weapons_17() -> String: "{\"id\":17,\"name\":\"Astronaut Comet\",\"evolvedName\":\"Homeward Meteor\",\"icon\":\"*\",\"color\":\"#ffd5ab\",\"description\":\"Falling comets explode among enemy clusters.\",\"evolvedDescription\":\"Astronaut Comet alternates with D-DAY Release. Damage +120%; area +35%.\",\"passive\":2,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":14}"

def weapons_18() -> String: "{\"id\":18,\"name\":\"Stage Beam\",\"evolvedName\":\"Golden Spotlight\",\"icon\":\"|\",\"color\":\"#fff0aa\",\"description\":\"A long stage beam strikes enemies along a line.\",\"evolvedDescription\":\"Stage Beam alternates with Poem Fragment. Damage +120%; area +35%.\",\"passive\":3,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":9}"

def weapons_19() -> String: "{\"id\":19,\"name\":\"Leaf Orbit\",\"evolvedName\":\"Museum Garden\",\"icon\":\"+\",\"color\":\"#94b89a\",\"description\":\"Orbiting leaves defend the space close to you.\",\"evolvedDescription\":\"Leaf Orbit alternates with Warm Hearth. Damage +120%; area +35%.\",\"passive\":6,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":4}"

def weapons_20() -> String: "{\"id\":20,\"name\":\"Indigo Composition\",\"evolvedName\":\"Order in Chaos\",\"icon\":\"O\",\"color\":\"#7b98dc\",\"description\":\"Ink fields pull enemies inward and repeatedly damage the chosen area.\",\"evolvedDescription\":\"Indigo Composition alternates with Moon Orbit. Damage +120%; area +35%.\",\"passive\":8,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":3}"

def weapons_21() -> String: "{\"id\":21,\"name\":\"Home Star\",\"evolvedName\":\"RJ Constellation\",\"icon\":\"*\",\"color\":\"#f6ddba\",\"description\":\"An RJ-inspired orbiting star strikes nearby enemies and launches homing letters.\",\"evolvedDescription\":\"Orbiting Home Stars launch homing letters and add targeted slowing spotlights. Damage +120%; area +35%.\",\"passive\":10,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":5}"

def weapons_22() -> String: "{\"id\":22,\"name\":\"Street Beat\",\"evolvedName\":\"HOPE Block Party\",\"icon\":\"x\",\"color\":\"#a5e38b\",\"description\":\"Leaves beat marks at your position. They arm after a delay and pulse at pursuers.\",\"evolvedDescription\":\"Street Beat alternates with Indigo Composition. Damage +120%; area +35%.\",\"passive\":3,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":20}"

def weapons_23() -> String: "{\"id\":23,\"name\":\"Dream Frame\",\"evolvedName\":\"TATA Dreamscape\",\"icon\":\"+\",\"color\":\"#c58da4\",\"description\":\"Surreal frames send projectiles outward in several directions.\",\"evolvedDescription\":\"Dream Frame alternates with Spotlight Snap. Damage +120%; area +35%.\",\"passive\":12,\"maxLevel\":8,\"evolutionRequires\":{\"weaponLevel\":8,\"passiveLevel\":1},\"evolutionSecondary\":5}"

def weapons() -> String:
  "[" ++ weapons_0() ++ "," ++ weapons_1() ++ "," ++ weapons_2() ++ "," ++ weapons_3() ++ "," ++ weapons_4() ++ "," ++ weapons_5() ++ "," ++ weapons_6() ++ "," ++ weapons_7() ++ "," ++ weapons_8() ++ "," ++ weapons_9() ++ "," ++ weapons_10() ++ "," ++ weapons_11() ++ "," ++ weapons_12() ++ "," ++ weapons_13() ++ "," ++ weapons_14() ++ "," ++ weapons_15() ++ "," ++ weapons_16() ++ "," ++ weapons_17() ++ "," ++ weapons_18() ++ "," ++ weapons_19() ++ "," ++ weapons_20() ++ "," ++ weapons_21() ++ "," ++ weapons_22() ++ "," ++ weapons_23() ++ "]"

def weapon_unlocks_0() -> String: "{\"id\":12,\"stageRelic\":0,\"hint\":\"Find Silk Spool in Forgotten Graveyard.\"}"

def weapon_unlocks_1() -> String: "{\"id\":14,\"condition\":{\"stat\":\"kills\",\"value\":100},\"hint\":\"Defeat 100 enemies across your runs.\"}"

def weapon_unlocks_2() -> String: "{\"id\":16,\"stageRelic\":2,\"hint\":\"Find SHOOKY Crumb in Wisp Marsh.\"}"

def weapon_unlocks_3() -> String: "{\"id\":17,\"stageRelic\":4,\"hint\":\"Find Astronaut Map in Infernal Maw.\"}"

def weapon_unlocks_4() -> String: "{\"id\":18,\"stageRelic\":1,\"hint\":\"Find Golden Filament in Midnight Library.\"}"

def weapon_unlocks_5() -> String: "{\"id\":22,\"stageRelic\":3,\"hint\":\"Find Street Cassette in Frozen Pass.\"}"

def weapon_unlocks() -> String:
  "[" ++ weapon_unlocks_0() ++ "," ++ weapon_unlocks_1() ++ "," ++ weapon_unlocks_2() ++ "," ++ weapon_unlocks_3() ++ "," ++ weapon_unlocks_4() ++ "," ++ weapon_unlocks_5() ++ "]"

def default_character() -> U32: 0
def default_stage() -> U32: 0
def default_arcana() -> U32: 0
def default_mode() -> U32: 0

def default_setup() -> String:
  "{\"character\":" ++ U32.show(default_character()) ++ ",\"stage\":" ++ U32.show(default_stage()) ++ ",\"arcana\":" ++ U32.show(default_arcana()) ++ ",\"mode\":" ++ U32.show(default_mode()) ++ "}"

def json() -> String:
  "{" ++ "\"ACHIEVEMENTS\":" ++ achievements() ++ "," ++ "\"ARCANA\":" ++ arcana() ++ "," ++ "\"CHARACTERS\":" ++ characters() ++ "," ++ "\"COLLECTIONS\":" ++ collections() ++ "," ++ "\"ENEMIES\":" ++ enemies() ++ "," ++ "\"META_UPGRADES\":" ++ meta_upgrades() ++ "," ++ "\"PASSIVES\":" ++ passives() ++ "," ++ "\"RUN_MODES\":" ++ run_modes() ++ "," ++ "\"STAGES\":" ++ stages() ++ "," ++ "\"STAGE_RELICS\":" ++ stage_relics() ++ "," ++ "\"UNIONS\":" ++ unions() ++ "," ++ "\"WEAPONS\":" ++ weapons() ++ "," ++ "\"WEAPON_UNLOCKS\":" ++ weapon_unlocks() ++ ",\"DEFAULT_SETUP\":" ++ default_setup() ++ "}"
