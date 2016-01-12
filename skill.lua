local action = {}

function action:dirt_kick()
end

function action:lore()
end

function action:berserk()
end

function action:bash()
end

local skilltable = {
  lore = {
    cp = 8,
    class = "wizard"
  },
  bash = {
    cp = 10,
    class = "warrior"
  },
  berserk = {
    cp = 10,
    class = "warrior"
  },
  sneak = {
    cp = 8,
    class = "thief"
  },
  lay_on_hands = {
    cp = 6,
    class = "cleric"
  },
  dirt_kick = {
    cp = 8,
    class = "warrior"
  },
  steal = {
    cp = 10,
    class = "thief"
  },
  robust = {
    cp = 8,
    class = "warrior"
  }
}

local skill = {}

function skill:perform(player, args)
end

function skill.getcp(skillname)
  return skilltable[skillname].cp
end

return skill
