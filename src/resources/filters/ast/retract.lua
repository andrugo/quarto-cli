function retract() 
  return {
    Div = function(div)
      local tag = pandoc.utils.stringify(div.attr.classes)
      local handler = postState.extendedAstNodeHandlers[tag]
      if handler ~= nil then
        local divTable = { attr = div.attr }
        local name
        local value
        for i, v in pairs(div.content) do
          if i % 2 == 1 then
            name = pandoc.utils.stringify(v)
          else
            value = v
            divTable[name] = value
          end
        end
        return handler.retract(divTable)
      end
      return div
    end,
  }
end