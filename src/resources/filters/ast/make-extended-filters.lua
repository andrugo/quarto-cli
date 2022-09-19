-- make-extended-filters.lua
-- creates lua filter loaders to support extended AST
-- Copyright (C) 2022 by RStudio, PBC

runExtendedFilters = function(doc, filters)
  for i, filter in ipairs(filters) do
    doc = doc:walk(filter)
  end
  return doc
end

local function wrapExtendedAst(handlers)
  function wrapFilter(handler)
    local wrappedFilter = {}
    for k,v in pairs(handler) do
      wrappedFilter[k] = v.handle
    end
  
    local theirDivHandler = (wrappedFilter.Div or 
      function(div) 
        return div 
      end)
  
    wrappedFilter.Div = function(div)
      local asPandocValue = function(filterResultItem)
        if filterResultItem == nil or filterResultItem == pandoc.Null then
          return filterResultItem
        end
  
        if quarto.utils.table.isarray(filterResultItem) then
          -- this is an integer-indexed table, so we iterate over
          -- the result and build it
          local outputArray = {}
          for i, v in pairs(filterResultItem) do
            local innerResult = asPandocValue(v)
            table.insert(outputArray, innerResult)
          end
          return outputArray
        end
  
        -- this is a string-indexed table, so it's a quarto
        -- extended ast node. build the pandoc representation and
        -- return it
        return quarto.ast.build(filterResultItem)
      end
  
      -- try to find quarto extended AST tag
      local astTag = div.attr.attributes["quarto-extended-ast-tag"]
      local astHandler = quarto.ast.resolveHandler(astTag)
      local filterHandler = astHandler and wrappedFilter[astHandler.astName]
  
      if filterHandler ~= nil then
        local nodeTable = quarto.ast.unbuild(div)
        return asPandocValue(filterHandler(nodeTable))
      else
        return theirDivHandler(div)
      end
    end
    return wrappedFilter
  end
  
  return mapOrCall(wrapFilter, handlers)
end

makeExtendedUserFilters = function(filterListName)
  local filters = {}
  for i, v in ipairs(param("quarto-filters")[filterListName]) do
    local v = pandoc.utils.stringify(v)
    table.insert(filters, makeWrappedFilter(v, wrapExtendedAst))
  end
  local filter = {
    Pandoc = function(doc)
      return runExtendedFilters(doc, filters)
    end  
  }
  return filter
end