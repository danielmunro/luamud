local skill = require "skill"

local race = {
  sizes = {
    medium = 2
  },
  list = {
    human = {
      name = "human",
      attr = { str = 15, int = 15, wis = 15, dex = 15, con = 15, cha = 15 },
      skills = {},
      size = 2
    },
    elf = {
      name = "elf",
      attr = { str = 13, int = 19, wis = 14, dex = 18, con = 11, cha = 17 },
      skills = {"lore", "sneak"},
      vuln = { "steel" },
      resist = { "magic" },
      size = 1
    },
    dwarf = {
      name = "dwarf",
      attr = { str = 19, int = 13, wis = 16, dex = 12, con = 18, cha = 12 },
      skills = {"berserk"},
      vuln = { "water" },
      resist = { "pound" },
      size = 1
    },
    giant = {
      name = "giant",
      attr = { str = 19, int = 12, wis = 13, dex = 11, con = 19, cha = 11 },
      skills = {"bash", "dirt_kick"},
      resist = { "fire", "ice" },
      vuln = { "magic", "mental" },
      size = 3
    },
    half_orc = {
      name = "half orc",
      attr = { str = 17, int = 14, wis = 14, dex = 13, con = 17, cha = 12 },
      skills = { "bash", "robust" },
      resist = { "poison" },
      vuln = { "magic" },
      size = 3
    },
    gnome = {
      name = "gnome",
      attr = { str = 11, int = 16, wis = 19, dex = 19, con = 13, cha = 16},
      skills = {"lay_on_hands", "steal"},
      resist = { "magic" },
      vuln = { "pound" },
      size = 1
    },
    critter = {
      name = "critter",
      attr = { str = 15, int = 15, wis = 15, dex = 15, con = 15, cha = 15 }
    }
  }
}

function race:tolevel(r)
  local tolevel = 0
  local race = self.list[r]

  for i, a in pairs(race.attr) do
    tolevel = tolevel + (a * 10)
  end

  if race.skills then
    for i, s in pairs(race.skills) do
      tolevel = tolevel + (skill.getcp(s) * 20)
    end
  end

  if race.vuln then
    for i, v in pairs(race.vuln) do
      tolevel = tolevel - 100;
    end
  end

  if race.resist then
    for i, v in pairs(race.resist) do
      tolevel = tolevel + 100;
    end
  end

  return tolevel
end

return race
