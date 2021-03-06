local room = require "room"
local mob = require "mob"
local location = require "location"
local area = require "area"
local item = require "item"
local f = require "functional"
local attributes = require "attributes"
local affect = require "affect"

local command = {
  priority = {
    s = "south",
    a = "affects"
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
      location:removemob(player.mob.id, roomfrom.id)
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

local function findmob(roomid, input)
  return f.first(location.rooms[roomid], function(mobid)
    local m = mob.list[mobid]
    if match(m.name, input) then return m end
  end)
end

local function finditem(invid, input)
  return f.first(item.inv[invid], function(i)
    if match(i.name, input) then return i end
  end)
end

function command.quit(player)
  location:removemob(player.mob.id, location.mobs[player.mob.id])
  player:save()
  player.client:close()
end

function command.gossip(player, args)
    broadcast(player.client:getpeername() .. " gossips, \"" .. table.concat(args, " ", 2) .. "\"")
end

function command.look(player, args)
  local roomid = location.mobs[player.mob.id]
  local r = room.list[roomid]

  -- looking at something
  if args and args[2] then

    -- is the player looking at a mob?
    local m = findmob(roomid, args[2])

    if m then
      local description = m.description or ""
      player:send(description .. m.name .. " " .. mob:conditionstr(m) .. ".")

      return
    end

    if handled then return end

    -- what about an item?
    local i = finditem(roomid, args[2])

    if not i then
      i = finditem(player.mob.id, args[2])
    end

    if i then
      player:send(i.description or i.name .. " is here.")
      return
    end

    -- item was not found
    player:send("You do not see that.")

    return
  end

  local message = r.name .. "\n" .. r.description .. "\n\n" ..

  -- directions
   f.reduce("Exits [", r.directions, function(message, roomid, dir)
    return message .. dir:sub(1, 1)
  end) .. "]\n" ..

  -- mobs
  f.reduce("", location.rooms[roomid], function(message, mobid)
    if mobid ~= player.mob.id then
      local m = mob.list[mobid]
      if m.longdesc then
        return message .. m.longdesc .. "\n"
      else
        return message .. m.name .. " is here.\n"
      end
    else
      return message
    end
  end) ..

  -- items in room
  f.reduce("", item.inv[roomid], function(message, i)
    return message .. i.name .. " is on the ground.\n"
  end)

  player:send(message:sub(1, -2))
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
  message = table.concat(args, " ", 2)
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

  local trainer = f.first(location.rooms[location.mobs[player.mob.id]], function(m)
    local listmob = mob.list[location.mobs[player.mob.id]]
    if listmob.trainer then return listmob end
  end)

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

function command.inventory(player)
  local message = "Your inventory:\n"
  if item.inv[player.mob.id] then
    for i, item in pairs(item.inv[player.mob.id]) do
      message = message .. item.name .. "\n"
    end
  else
    message = message .. "carrying nothing\n"
  end
  player.client:send(message)
end

function command.reset(player, args)
  local roomid = location.mobs[player.mob.id]
  local r = location.rooms[roomid]
  for i, m in pairs(r) do
    if mob.list[m] then
      area:addmobreset(m, roomid)
    else
      print("reset for nonexistent mob", i, m, roomid)
    end
  end
  if item.inv[roomid] then
    for i, item in pairs(item.inv[roomid]) do
      area:additemreset(item, roomid)
    end
  end
  player:send("Room reset.")
end

function command.drop(player, args)
  local itemname = table.concat(args, " ", 2)
  for i, it in pairs(item.inv[player.mob.id]) do
    if match(it.name, itemname) then
      table.remove(item.inv[player.mob.id], i)
      table.insert(item.inv[location.mobs[player.mob.id]], it)
      player:send("You drop " .. it.name .. ".")
      broadcastroom(player, player.mob.name .. " drops " .. it.name .. ".")
      return
    end
  end

  player:send("You don't have anything like that.")
end

function command.get(player, args)
  local itemname = table.concat(args, " ", 2)
  for i, it in pairs(item.inv[location.mobs[player.mob.id]]) do
    if match(it.name, itemname) then
      table.remove(item.inv[location.mobs[player.mob.id]], i)
      table.insert(item.inv[player.mob.id], it)
      player:send("You pick up " .. it.name .. ".")
      broadcastroom(player, player.mob.name .. " picks up " .. it.name .. ".")
      return
    end
  end

  player:send("You don't see anything like that here.")
end

function command.affects(player)
  player:send("Affecting you:\n" ..
    f.reduce("", affect:getaffects(player.mob.id), function(message, a)
      return message .. a.name .. ": " .. a.timeout .. "\n"
    end):sub(1, -2))
end

function command.bless(player)
  affect:new(player.mob.id, "bless", 2, "You feel less blessed.")
  player:send("You feel blessed.")
end

function command.item(player, args)
  local action = args[2]
  if match("create", action) then
    local name = table.concat(args, " ", 3)
    local i = item:new(name)
    table.insert(item.inv[player.mob.id], i)
    player:send("You create " .. name .. " out of the void")
  elseif match("material", action) then
    local i = finditem(player.mob.id, args[3])
    i.material = args[4]
  elseif match("weight", action) then
    local i = finditem(player.mob.id, args[3])
    i.weight = tonumber(args[4])
  else

    local selecteditem = finditem(player.mob.id, args[2])

    if not selecteditem then
      player:send("That item not found. Format is: item <item name> <attr1> <value1> <attr2> <value2> ...")
      return
    end
    local attrupdate = {}
    local i = 3

    -- display information about the item
    if not args[i] then
      local i = finditem(player.mob.id, args[3])
      local attrstr = ""
      f.each(i.attr, function(v, attr)
        attrstr = attrstr .. "+" .. v .. " " .. attr .. " "
      end)
      player:send(i.id .. "\n" .. i.name .. "\n" .. "weight: " .. i.weight ..
      ", material: " .. i.material .. "\n" .. attrstr)
      return
    end

    -- assign attributes to the item
    while args[i] do
      if not attributes.isattr(args[i]) then
        player:send("That is not a valid attribute. Format is: item <item name> <attr1> <value1> <attr2> <value2> ...")
        return
      end
      args[i+1] = tonumber(args[i+1])
      if type(args[i+1]) ~= "number" then
        player:send("Attribute value must be a number. Format is: item <item name> <attr1> <value1> <attr2> <value2> ...")
        return
      end
      attrupdate[args[i]] = args[i+1]
      i = i + 2
    end

    f.each(attrupdate, function(i, k)
      selecteditem.attr[k] = i
    end)

    player:send("Item updated")
  end
end

function command.mob(player, args)
  local action = args[2]
  if action == "create" then
    local m = mob:new("a critter")
    m.isnpc = true
    location:addmob(m.id, location.mobs[player.mob.id])
    area:addmob(m)
    player:send("You conjure a critter from the void.")
    broadcastroom(player, player.mob.name .. " waves its hands and a critter pops into existence from the void.")
  elseif action == "report" then
    local message = "mobs in room:\n"
    for i, m in pairs(area.list[room.list[location.mobs[player.mob.id]].area].mobs) do
      message = message .. m.name .. " (#" .. m.id .. ")\n"
    end
  else
    player:send("Not understood.")
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
        location.rooms[r.id] = {}
        player:send("A room is summoned from the void.")
      end
    else
      player:send("That is not a direction.")
    end
  elseif args[2] == "name" or args[2] == "description" then
    local property = args[2]
    room:update(location.mobs[player.mob.id], property, table.concat(args, " ", 3))
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
    player:send("That is not a valid direction. Command is: gate <direction>")
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
    player:save()
    player:send("Saved. Remember, saving is automatic.")
  elseif args[2] == "boinga" then
    for i, a in pairs(area.list) do
      area:save(a)
    end
    player:send("Boinga is saved.")
  end
end

return command
