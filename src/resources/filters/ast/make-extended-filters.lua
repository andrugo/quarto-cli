-- make-extended-filters.lua
-- creates lua filter loaders to support extended AST
-- Copyright (C) 2022 by RStudio, PBC

-- REVIEW this seems ugly but necessary?
runExtendedFilters = function(doc, filters)
  local result = doc
  for i, filter in ipairs(filters) do
    result = result:walk(filter)
  end
  return result
end

local function wrapExtendedAst(handlers)
  local result = {}

  for k,v in pairs(handlers) do
    result[k] = v.handle
  end

  local theirDivHandler = (result.Div or 
    function(div) 
      return div 
    end)

  result.Div = function(div)
    -- try to find quarto extended AST tag
    local astTag = div.attr.attributes["quarto-extended-ast-tag"]
    if astTag ~= nil and result[astTag] ~= nil then
        -- wrap to table
      local extendedAstNode = {
        attr = div.attr
      }
      local name
      local value
      for i, innerDiv in pairs(div.content) do
        if i % 2 == 1 then
          name = pandoc.utils.stringify(innerDiv.content)
        else
          value = innerDiv
          extendedAstNode[name] = value
        end
      end
      extendedAstNode = result[astTag](extendedAstNode) or extendedAstNode
      -- unwrap to div
      local resultAttr
      local blocks = {}
      for name, value in pairs(extendedAstNode) do
        if name == "attr" then
          resultAttr = value
        else
          table.insert(blocks, pandoc.Str(name))
          table.insert(blocks, value)
        end                    
      end
      return pandoc.Div(blocks, resultAttr)
    else
      return theirDivHandler(div)
    end
  end
  return result
end

makeExtendedUserFilters = function(filterListName)
  local filters = {}
  local filter = {
    Meta = function(meta)
      for i, v in ipairs(meta["quarto-filters"][filterListName]) do
        local v = pandoc.utils.stringify(v)
        table.insert(filters, makeWrappedFilter(v, wrapExtendedAst))
      end
    end,
    
    Pandoc = function(doc)
      return runExtendedFilters(doc, filters)
    end  
  }
  return filter
end