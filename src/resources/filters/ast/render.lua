function renderExtendedNodes() 
  return {
    Div = function(div)
      local tag = pandoc.utils.stringify(div.attr.attributes[kExtendedAstTag])      
      local handler = quarto.ast.resolveHandler(tag)
      if handler == nil then
        return div
      end
      local divTable = quarto.ast.unbuild(div)
      return handler.render(divTable)
    end
  }
end