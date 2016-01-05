local room = require "room"
local persister = require "persister"
local mob = require "mob"

local command = {
  priority = {
    s = "south"
  }
}

function command.help(player, args)
  local topic = args[2]
  if topic == "create" then
    player.client:send("'Create' is used to bring new objects into the game world.\n\nFor rooms, the syntax is: 'create room <direction>'\n")
  else
    player.client:send("Use the help command to learn more about the game.\n")
  end
end

function command.saverealm(player)
  persister.persist(player.room)
  player.client:send("Realm persisted.\n");
end

function command.quit(player)
  player.room:removemob(player.mob)
  player.client:close()
end

function command.gossip(player, args)
    table.remove(args, 1)
    broadcast(player.client:getpeername() .. " gossips, \"" .. table.concat(args, " ") .. "\"\n")
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
        table.insert(mobs, v.brief .. "\n")
      else
        table.insert(mobs, v.name .. " is here.\n")
      end
    end
  end

  player.client:send(
    r.name .. "\n" ..
    r.description .. "\n\n" ..
    "Exits [" .. table.concat(directions) .. "]\n" ..
    table.concat(mobs)
  )
end

function command.mob(player, args)
  local action = args[2]
  if action == "create" then
    table.insert(player.room.mobs, mob:new("a critter"))
  end
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
        player.client:send("A room already exists.\n")
      else
        r = room:new();
        r.name = "A new room"
        r.description = "A new room has popped into existence from the void. It is up to you to customize it."
        player.room.directions[direction] = r.id
        r.directions[room.oppositedir(direction)] = player.room.id
        player.client:send("A room is summoned from the void.\n")
        room.rooms[r.id] = r
      end
    else
      player.client:send("That is not a direction.\n")
    end
  elseif prop == "name" or prop == "description" or prop == "mvcost" then
    player.room[prop] = value
    player.client:send("Room " .. prop .. " updated.\n")
  elseif prop == "list" then
    local message = ""
    for i, v in pairs(room.rooms) do
      message = message .. i .. ": " .. v.name .. "\n"
    end
    player.client:send("In-game rooms: " .. message);
  else
    player.client:send("Not understood.\n")
  end
end

local function move(player, direction)
  local roomto = room.rooms[player.room.directions[direction]]
  local roomfrom = player.room

  if roomto then

    local mvcost = roomto.mvcost or 1
    if player.mob.attr.mv >= mvcost then
      player.mob.attr.mv = player.mob.attr.mv - mvcost
      player.mob.roomid = roomto.id
      roomfrom:removemob(player.mob)
      broadcastroom(roomfrom.id, player, player.mob.name .. " leaves heading " .. direction .. ".\n")
      player.room = roomto
      broadcastroom(roomto.id, player, player.mob.name .. " arrives from the " .. room.oppositedir(direction) .. ".\n")
      roomto:addmob(player.mob)
      command.look(player)
    else
      player.client:send("You are too tired to move.\n")
    end
  else
    player.client:send("Alas, that direction does not exist\n")
  end
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
  player.client:send("You say, \"" .. message .. "\"")
  broadcastroom(
    player.room.id,
    player,
    player.client:getpeername() .. " says, \"" .. message .. "\"\n"
  )
end

return command
