-- make-extended-filters.lua
-- creates lua filter loaders to support extended AST
-- Copyright (C) 2022 by RStudio, PBC

-- REVIEW this seems ugly but necessary?
runExtendedFilters = function(doc, filters)
  local result = doc
  for i, filter in ipairs(filters) do
    if filter.Pandoc ~= nil then
      local newPandoc = filter.Pandoc(result)
      if newPandoc ~= nil then
        result = newPandoc
      end
    end
    if filter.Meta ~= nil then
      local newMeta = filter.Meta(result.meta)
      if newMeta ~= nil then
        result.meta = newMeta
      end
    end

    local blocks = {}
    for _, block in pairs(result.blocks) do
      table.insert(blocks, pandoc.walk_block(block, filter))
    end
    result = pandoc.Pandoc(blocks, result.meta)
  end
  return result
end

local function wrapExtendedAst(handlers)
  local result = {}

  for k,v in pairs(handlers) do
    result[k] = v.handle
  end

  if result.Div ~= nil then
    local theirDivHandler = (result.Div or 
      function(div) 
        return div 
      end)
    result.Div = function(div)
      -- try to find quarto extended AST tag
      local astTag = div.attr["quarto-extended-ast-tag"]
      if astTag ~= nil and result[astTag] ~= nil then
        -- wrap to table
        local extendedAstNode = {
          attr = div.attr
        }
        for i, div in pairs(div.content) do
          local name = pandoc.utils.stringify(div.content[1])
          local value = div.content[2]
        end
        extendedAstNode = result[astTag](extendedAstNode)
        -- unwrap to div
        local resultAttr
        local blocks = {}
        for name, value in pairs(extendedAstNode) do
          if name == "attr" then
            resultAttr = value
          else
            table.insert(blocks, Pandoc.Str(name))
            table.insert(blocks, value)
          end                    
        end
        return pandoc.Div(blocks, resultAttr)
      else
        return theirDivHandler(div)
      end
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