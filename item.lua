local attributes = require "attributes"

local item = {
  materials = {
    "wood", "stone", "steel", "copper", "leather", "void"
  },
  inv = {}
}

function item:addinv(invid, item)
  if not self.inv[invid] then
    self.inv[invid] = {}
  end

  table.insert(self.inv[invid], item)
end

function item:new(item)
  local newitem = {
    name = name,
    weight = 0,
    material = "void",
    id = uuid(),
    attr = attributes.new()
  }

  return newitem
end

return item
