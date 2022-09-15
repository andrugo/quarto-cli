function extend() 
  return {
    Div = function(div)
      local tag = pandoc.utils.stringify(div.attr.classes)
      local handler = preState.extendedAstNodeHandlers[tag]
      if handler ~= nil then
        local divTable = handler.extend(div)
        local blocks = {}
        for name, value in pairs(divTable) do
          if name ~= "attr" then
            table.insert(blocks, pandoc.Str(name))
            table.insert(blocks, value)
          end
        end
        div.attr.attributes["quarto-extended-ast-tag"] = handler.name
        return pandoc.Div(blocks, div.attr)
      end
      return div
    end
  }
end