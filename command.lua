local room = require "room"
local mob = require "mob"
local location = require "location"
local area = require "area"

local command = {
  priority = {
    s = "south"
  }
}

local function move(player, direction)
  local roomfrom = room.list[location.mobs[player.mob.id]]
  local roomto = room.list[roomfrom.directions[direction]]

  if roomto then

    local mvcost = roomto.mvcost or 1
    if player.mob.mv >= mvcost then
      player.mob.mv = player.mob.mv - mvcost
      broadcastroom(player, player.mob.name .. " leaves heading " .. direction .. ".")
      location:removemob(player.mob.id)
      location:addmob(player.mob.id, roomto.id)
      broadcastroom(player, player.mob.name .. " arrives from the " .. room.oppositedir(direction) .. ".")
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
  local l = location.mobs[player.mob.id]
  local r = room.list[l]
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
    for i, v in pairs(location.rooms[l]) do
      if v ~= player.mob.id then
        local m = mob.list[v]
        if m.longdesc then
          table.insert(mobs, "\n" .. m.longdesc)
        else
          table.insert(mobs, "\n" .. m.name .. " is here.")
        end
      end
    end

    player:send(
      r.name .. "\n" ..
      r.description .. "\n\n" ..
      "Exits [" .. table.concat(directions) .. "]" ..
      table.concat(mobs)
    )
  end
end

function command.score(player)
  local m = player.mob
  player:send("You are " .. m.name .. ", a level " .. m.level .. " " .. m.race .. ".\n" ..
  m.hp .. "/" .. m.attr["hp"] .. "hp, " ..
  m.mana .. "/" .. m.attr["mana"] .. "mana, " ..
  m.mv .. "/" .. m.attr["mv"] .. "mv\n" ..
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
    player.mob.name .. " says, \"" .. message .. "\""
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

function command.mob(player, args)
  local action = args[2]
  if action == "create" then
    mob:new("a critter")
    location:addmob(mob.id, location.mobs[player.mob.id])
    player:send("You conjure a critter from the void.")
    broadcastroom(player, player.mob.name .. " waves its hands and a critter pops into existence from the void.")
  end
end

function command.area(player, args)

  if args[2] == "create" then
    local id = args[3]
    local a
    player:ask("New area id is: '" .. id .. "', confirm? (yes/no) ", function(args)
      if args[1] == "yes" then
        area:new(id)
        player:ask("What is the proper name for this new area? ", function(args)
          area.list[id].name = table.concat(args, " ")
          player:ask("What should the credits line be? ", function(args)
            area.list[id].credits = table.concat(args, " ")
            area:roomswap(location.mobs[player.mob.id], room.list[location.mobs[player.mob.id]].area, id)
            player:send("Area created!")
          end)
        end)
      else
        player:send("Cancel new area request.")
      end
    end)
  elseif args[2] == "set" then
  elseif args[2] == nil then
    local r = room.list[location.mobs[player.mob.id]]
    local a = area.list[r.area]
    player:send("You are in " .. a.name .. ". Credits:\n" .. a.credits)
  end
end

function command.room(player, args)
  if args[2] == "create" then
    direction = args[3]
    if room.isdirection(direction) then
      local playerlocation = location.mobs[player.mob.id]
      local playerroom = room.list[playerlocation]
      if playerroom.directions[direction] then
        player:send("A room already exists.")
      else
        r = room:new()
        r.name = "A new room"
        r.description = "A new room has popped into existence from the void. It is up to you to customize it."
        r.area = playerroom.area
        area:addroom(r)
        room:to(playerlocation, direction, r.id)
        room:to(r.id, room.oppositedir(direction), playerlocation)
        player:send("A room is summoned from the void.")
      end
    else
      player:send("That is not a direction.")
    end
  elseif args[2] == "name" or args[2] == "description" then
    local property = args[2]
    table.remove(args, 1)
    table.remove(args, 1)
    room:update(location.mobs[player.mob.id], property, table.concat(args, " "))
    player:send("You updated the room " .. property .. ".")
  else
    player:send("Cannot create that.")
  end
end

function command.flag(player, args)
  if args[2] == nil then
    if player.flag then
      player:send("Your flag is at " .. room.list[player.flag].name)
    else
      player:send("Set a flag with: flag set")
    end
  elseif args[2] == "set" then
    player.flag = location.mobs[player.mob.id]
    player:send("You set your flag at " .. room.list[player.flag].name)
  end
end

function command.gate(player, args)
  if room.isdirection(args[2]) then
    if not player.flag then
      player:send("You must set a flag first.")
    else
      room:to(location.mobs[player.mob.id], args[2], player.flag)
      player:send("Gate created successfully!")
    end
  else
    player:send("That is not a valid direction. Command is: proxy <direction>")
  end
end

function command.proxy(player, args)
  if room.isdirection(args[2]) then
    if not player.flag then
      player:send("You must set a flag first.")
    else
      room:to(location.mobs[player.mob.id], args[2], player.flag)
      room:to(player.flag, room.oppositedir(args[2]), location.mobs[player.mob.id])
      player:send("Proxy created successfully!")
    end
  else
    player:send("That is not a valid direction. Command is: proxy <direction>")
  end
end

function command.save(player, args)
  if args[2] == nil then
    player:send("Saving not implemented yet")
  elseif args[2] == "boinga" then
    for i, a in pairs(area.list) do
      area:save(a)
    end
    player:send("Boinga is saved.")
  end
end

return command
