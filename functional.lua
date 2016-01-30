local functional = {}

function functional.map(array, func)

  local newarray = {}

  for i, v in pairs(array) do
    newarray[i] = func(v, i)
  end

  return newarray

end

function functional.filter(array, func)

  local newarray = {}

  for i, v in pairs(array) do
    if func(v, i) then
      newarray[i] = v
    end
  end

  return newarray

end

function functional.reduce(result, array, func)

  for i, v in pairs(array) do
    result = func(result, v, i)
  end

  return result

end

function functional.each(array, func)

  for i, v in pairs(array) do
    func(v, i)
  end

end

function functional.first(array, func)

  if not func then
    func = function(v, i) return v end
  end

  for i, v in pairs(array) do
    local r = func(v, i)

    if r then return r end
  end
end

return functional
