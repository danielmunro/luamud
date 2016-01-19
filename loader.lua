local area = require "area"
local room = require "room"
local mob = require "mob"
local reset = require "reset"
local loader = {
  buf = {},
  line = 1,
  cursor = 1,
  filename = ""
}

local function split(inputstr, sep)
  if sep == nil then
    sep = "\r\n"
  end

  local t = {}
  local i = 1

  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = string.gsub(str, "\9", " ")
    i = i + 1
  end

  return t
end

function loader:load(filename)
  print("loading " .. filename)
  local fp, err = assert(io.open(filename, "r"))
  self.buf = split(fp:read("*all"))
  fp:close()
  self.filename = filename
  self.line = 1
  self.cursor = 1
  local line = self:nextbuf()
  while line do
    if line == "#AREA" then
      area:load(self)
    elseif line == "#MOBILES" then
      mob:load(self)
    elseif line == "#OBJECTS" then
    elseif line == "#ROOMS" then
      room:load(self)
    elseif line == "#RESETS" then
      reset:load(self)
    end
    line = self:nextbuf()
  end
end

function loader:done()
  for i, r in pairs(reset.resets) do
    if room.rooms[r.roomid] and mob.mobs[r.mob] then
      room.rooms[r.roomid]:addmob(mob.mobs[r.mob])
    else
      print("mapping error 2")
      local pl = require "pl.pretty"
      pl.dump(r)
      pl.dump(room.rooms[r.roomid])
      pl.dump(mob.mobs[r.mob])
      print("--------------------")
    end
  end
end

function loader:nextbuf()
  if self.buf[self.line] == nil then
    return nil
  end

  local line = string.sub(self.buf[self.line], self.cursor)
  self.line = self.line + 1
  self.cursor = 1

  return line
end

function loader:peekbuf(endpos)
  return string.sub(self.buf[self.line], self.cursor, endpos)
end

function loader:string()
  local buf = ""
  while true do
    local nbuf = self:nextbuf()
    if nbuf == nil then
      return nil
    end
    buf = buf .. nbuf
    local stop = string.find(buf, "~")
    if stop ~= nil then
      buf = string.sub(buf, 1, stop-1)
      return buf
    end
    buf = buf .. "\n"
  end
end

function loader:nextval()
  local value = ""

  while true do
    if self:cursornewline() then
      return value
    end
    local next = string.sub(self.buf[self.line], self.cursor, self.cursor)
    if value == "" and next == " " then
    else
      if next == " " then
        self.cursor = self.cursor + 1
        return value
      end
      value = value .. next
    end
    self.cursor = self.cursor + 1
  end

  return value
end

function loader:nextnum()
  local value = ""

  while true do
    if self:cursornewline() and value then
      return tonumber(value)
    end
    local next = string.sub(self.buf[self.line], self.cursor, self.cursor)
    if value == "" and next == " " then
    else
      if tonumber(next) ~= nil or ((next == "-" or next == "+") and value == "") then
        value = value .. next
      else
        return tonumber(value)
      end
    end
    self.cursor = self.cursor + 1
  end
end

function loader:cursornewline()
  if self.cursor > string.len(self.buf[self.line]) then
    self.line = self.line + 1
    self.cursor = 1
    return true
  end

  return false
end

function loader:value(breaker)
  local buf = ""
  local char = self:character(breaker)
  while char ~= " " and char ~= nil do
    buf = buf .. char
    char = self:character(breaker)
  end

  return buf
end

function loader:character(breaker)
  if self.cursor > string.len(self.buf[self.line]) then
    if breaker then
      return nil
    else
      self:nextbuf()
    end
  end

  local value = string.sub(self.buf[self.line], self.cursor, self.cursor)
  self.cursor = self.cursor + 1

  if value == " " and not breaker then
    return self:character(true)
  end

  return value
end

return loader
