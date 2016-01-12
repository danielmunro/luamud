local room = require "room"
local persister = require "persister"
local mob = require "mob"

local command = {
  priority = {
    s = "south"
  }
}

local function move(player, direction)
  local roomto = room.rooms[player.room.directions[direction]]
  local roomfrom = player.room

  if roomto then

    local mvcost = roomto.mvcost or 1
    if player.mob.attr.mv >= mvcost then
      player.mob.attr.mv = player.mob.attr.mv - mvcost
      player.mob.roomid = roomto.id
      roomfrom:removemob(player.mob)
      broadcastroom(player, player.mob.name .. " leaves heading " .. direction .. ".")
      player.room = roomto
      broadcastroom(player, player.mob.name .. " arrives from the " .. room.oppositedir(direction) .. ".")
      roomto:addmob(player.mob)
      command.look(player)
    else
      player:send("You are too tired to move.")
    end
  else
    player:send("Alas, that direction does not exist.")
  end
end

function command.help(player, args)
  local topic = args[2]
  if topic == "create" then
    player:send("'Create' is used to bring new objects into the game world.\n\nFor rooms, the syntax is: 'create room <direction>'")
  else
    player:send("Use the help command to learn more about the game.")
  end
end

function command.quit(player)
  player.room:removemob(player.mob)
  player.client:close()
end

function command.gossip(player, args)
    table.remove(args, 1)
    broadcast(player.client:getpeername() .. " gossips, \"" .. table.concat(args, " ") .. "\"")
end

function command.look(player)
  local r = player.room

  local directions = {}
  for i, v in pairs(player.room.directions) do
    table.insert(directions, string.sub(i, 1, 1))
  end

  local mobs = {}
  for i, v in pairs(player.room.mobs) do
    if v ~= player.mob then
      if v.brief then
        table.insert(mobs, v.brief)
      else
        table.insert(mobs, v.name .. " is here.")
      end
    end
  end

  player:send(
    r.name .. "\n" ..
    r.description .. "\n\n" ..
    "Exits [" .. table.concat(directions) .. "]\n" ..
    table.concat(mobs, "\n")
  )
end

function command.score(player)
  local m = player.mob
  player:send("You are " .. m.name .. ", a level " .. m.level .. " " .. m.race .. ".\n" ..
  m.attr["hp"] .. "/" .. m.maxattr["hp"] .. "hp, " ..
  m.attr["mana"] .. "/" .. m.maxattr["mana"] .. "mana, " ..
  m.attr["mv"] .. "/" .. m.maxattr["mv"] .. "mv\n" ..
  m.attr["str"] .. "(" .. m:getattr("str") .. ") str, " ..
  m.attr["int"] .. "(" .. m:getattr("int") .. ") int, " ..
  m.attr["wis"] .. "(" .. m:getattr("wis") .. ") wis, " ..
  m.attr["dex"] .. "(" .. m:getattr("dex") .. ") dex, " ..
  m.attr["con"] .. "(" .. m:getattr("con") .. ") con, " ..
  m.attr["cha"] .. "(" .. m:getattr("cha") .. ") cha\n" ..
  "Experience: " .. m.xp.total .. ". " .. m.xp.tnl .. "xp to next level.")
end

function command.north(player)
  move(player, "north")
end

function command.south(player)
  move(player, "south")
end

function command.east(player)
  move(player, "east")
end

function command.west(player)
  move(player, "west")
end

function command.up(player)
  move(player, "up")
end

function command.down(player)
  move(player, "down")
end

function command.say(player, args)
  table.remove(args, 1)
  message = table.concat(args, " ")
  player:send("You say, \"" .. message .. "\"")
  broadcastroom(
    player,
    player.client:getpeername() .. " says, \"" .. message .. "\""
  )
end

function command.train(player, args)

  if not args then
    player:send("Train what?")
    return
  end

  local attr = args[2]
  local attrs = {str = "strength", int = "intelligence", wis = "wisdom", dex = "dexterity", con = "constitution", cha = "charisma"}
  local stats = {hp = 1, mana = 1, mv = 1}
  local trainer = false

  for i, m in pairs(player.room.mobs) do
    if m.trainer then
      trainer = m
      break
    end
  end

  if not trainer then
    player:send("There are no trainers here.")
    return
  end

  if attrs[attr] then
    if player.mob.attr[attr] < player.mob.maxattr[attr] then
      player.mob.attr[attr] = player.mob.attr[attr] + 1
      player:send(trainer.name .. " provides you with sacred knowledge and training. Your " .. attrs[attr] .. " increases!")
    else
      player:send(trainer.name .. " says, \"You have already achieved your potential.\"")
    end
  elseif stats[attr] then
    player.mob.maxattr[attr] = player.mob.maxattr[attr] + 10
    player:send(trainer.name .. " provides you with sacred knowledge and training. Your " .. attr .. " increases!")
  else
    player:send(trainer.name .. " says, \"I cannot train you in that.\"")
  end
end

-- admin commands

function command.mob(player, args)
  local action = args[2]
  if action == "create" then
    table.insert(player.room.mobs, mob:new("a critter"))
    player:send("You conjure a critter from the void.")
    broadcastroom(player, "A critter pops into existence from the void.")
  end
end

function command.saverealm(player)
  persister.persist(player.room)
  player:send("Realm persisted.");
end

function command.room(player, args)
  local prop = args[2]
  table.remove(args, 1)
  table.remove(args, 1)
  local value = table.concat(args, " ")
  if prop == "create" then
    direction = args[1]
    if room.isdirection(direction) then
      if player.room.directions[direction] then
        player:send("A room already exists.")
      else
        r = room:new();
        r.name = "A new room"
        r.description = "A new room has popped into existence from the void. It is up to you to customize it."
        player.room.directions[direction] = r.id
        r.directions[room.oppositedir(direction)] = player.room.id
        player:send("A room is summoned from the void.")
        room.rooms[r.id] = r
      end
    else
      player:send("That is not a direction.")
    end
  elseif prop == "name" or prop == "description" or prop == "mvcost" then
    player.room[prop] = value
    player:send("Room " .. prop .. " updated.")
  elseif prop == "list" then
    local message = ""
    for i, v in pairs(room.rooms) do
      message = message .. i .. ": " .. v.name .. "\n"
    end
    player.client:send("In-game rooms: " .. message);
  else
    player:send("Not understood.")
  end
end

return command
