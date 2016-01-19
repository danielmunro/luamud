local room = require "room"
local persister = require "persister"
local mob = require "mob"

local command = {
  priority = {
    s = "south"
  }
}

local function move(player, direction)
  local roomfrom = room.rooms[player.roomid]
  local roomto = room.rooms[roomfrom.directions[direction]]

  if roomto then

    local mvcost = roomto.mvcost or 1
    if player.mob.attr.mv >= mvcost then
      player.mob.attr.mv = player.mob.attr.mv - mvcost
      player.mob.roomid = roomto.id
      roomfrom:removemob(player.mob)
      broadcastroom(player, player.mob.name .. " leaves heading " .. direction .. ".")
      player.roomid = roomto.id
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
  room.rooms[player.roomid]:removemob(player.mob)
  player.client:close()
end

function command.gossip(player, args)
    table.remove(args, 1)
    broadcast(player.client:getpeername() .. " gossips, \"" .. table.concat(args, " ") .. "\"")
end

function command.look(player, args)
  local r = room.rooms[player.roomid]
  if args and args[2] ~= nil then
    for i, m in pairs(r.mobs) do
      for word in m.name:gmatch("%w+") do
        if word:sub(1, args[2]:len()) == args[2] then
          player:send(m.description)
          return
        end
      end
    end
  else
    local directions = {}
    for i, v in pairs(r.directions) do
      table.insert(directions, string.sub(i, 1, 1))
    end

    local mobs = {}
    for i, v in pairs(r.mobs) do
      if v ~= player.mob then
        if v.longdesc then
          table.insert(mobs, v.longdesc)
        else
          table.insert(mobs, v.name .. " is here.\n")
        end
      end
    end

    player:send(
      r.name .. "\n" ..
      r.description .. "\n\n" ..
      "Exits [" .. table.concat(directions) .. "]\n" ..
      table.concat(mobs)
    )
  end
end

function command.score(player)
  local m = player.mob
  player:send("You are " .. m.name .. ", a level " .. m.level .. " " .. m.race .. ".\n" ..
  m.attr["hp"] .. "/" .. m.maxattr["hp"] .. "hp, " ..
  m.attr["mana"] .. "/" .. m.maxattr["mana"] .. "mana, " ..
  m.attr["mv"] .. "/" .. m.maxattr["mv"] .. "mv\n" ..
  m:baseattr("str") .. "(" .. m:getattr("str") .. ") str, " ..
  m:baseattr("int") .. "(" .. m:getattr("int") .. ") int, " ..
  m:baseattr("wis") .. "(" .. m:getattr("wis") .. ") wis, " ..
  m:baseattr("dex") .. "(" .. m:getattr("dex") .. ") dex, " ..
  m:baseattr("con") .. "(" .. m:getattr("con") .. ") con, " ..
  m:baseattr("cha") .. "(" .. m:getattr("cha") .. ") cha\n" ..
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

return command
