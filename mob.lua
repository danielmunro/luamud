local mob = {}

function mob.new(name)
  local m = {
    name = name,
    isnpc = true
  }

  return m
end

return mob
