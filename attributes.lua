local attributes = {}

function attributes.new()
  local a = {
    str = 0,
    int = 0,
    wis = 0,
    dex = 0,
    con = 0,
    hit = 0,
    dam = 0
  }
end

function attributes.isattr(attr)
  return attr == "str" or attr == "int" or attr == "wis" or attr == "dex"
    or attr == "con" or attr == "hit" or attr == "dam" or attr == "hp"
    or attr == "mv" or attr == "mana"
end

return attributes
