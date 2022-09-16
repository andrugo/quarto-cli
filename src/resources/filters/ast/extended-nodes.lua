local handlers = {
  {
    -- use either className or classPattern
    className = "fancy-callout",
    -- className = "tag-name"
    -- classPattern = function(class)
    --   -- return true if matches
    -- end,

    -- optional: makePandocExtendedDiv
    -- supply makePandocExtendedDiv if you need to construct
    -- your want to create and extended pandoc Div
    -- 
    -- This is here as an escape hatch, we expect most developers
    -- to not need it.
    -- makePandocExtendedDiv = function(table)
    --   -- returns a pandoc Div that can be parsed back into a table
    --   -- later use
    -- end

    -- the name of the ast node, used as a key in extended ast filter tables
    astName = "FancyCallout",

    -- a function that takes the extended ast node as supplied in user markdown
    -- and parses it into a table. if "attr" is set, then that is used
    -- as the attr attribute of the Div that will hold it.
    parse = function(div)
      return {
        -- the value of class must either be equal to className
        -- or be such that classPattern() returns true

        -- class must be a string
        class = pandoc.utils.stringify(div.attr.classes),
        
        -- attr, if provided, must be a pandoc Attr
        attr = div.attr,

        -- all other fields must be pandoc Blocks
        title = div.content[1],
        content = div.content[2],
      }
    end,

    -- either a function that unconditionally renders the extendedNode into
    -- output, or a table of functions, whose keys are the output formats
    
    render = function(extendedNode)
      local blocks = {}
      table.insert(blocks, extendedNode.title)
      table.insert(blocks, extendedNode.content)
      extendedNode.attr.attributes["quarto-extended-ast-tag"] = nil
      return pandoc.Div(blocks, extendedNode.attr)
    end,
    -- render = {
    --   html = function(extendedNode)
    --     -- render to html
    --   end,
    --   pdf = function(extendedNode)
    --     -- render to pdf
    --   end,
    --   docx = function(extendedNode)
    --     -- render to docx
    --   end,
    --   default = function(extendedNode)
    --     -- fallback format
    --   end,
    -- }
  },
}

kExtendedAstTag = "quarto-extended-ast-tag"

quarto.ast = {
  addHandler = function(handler)
    local state = (preState or postState).extendedAstHandlers
    if handler.className ~= nil then
      state.namedHandlers[handler.className] = handler
    elseif handler.classPattern ~= nil then
      table.insert(state.patternHandlers, handler)
    else
      print("ERROR: handler must have either className or classPattern")
      quarto.utils.dump(handler)
      os.exit(1)
    end
  end,

  resolveHandler = function(name)
    local state = (preState or postState).extendedAstHandlers
    if state.namedHandlers ~= nil then
      return state.namedHandlers[name]
    end
    for i, v in pairs(state.patternHandlers) do
      if v.classPattern(name) then
        return v
      end
    end
    return nil
  end,

  unbuild = function(extendedAstNode)
    local name = extendedAstNode.attr.attributes["quarto-extended-ast-tag"]
    local handler = quarto.ast.resolveHandler(name)
    if handler == nil then
      print("ERROR: couldn't find a handler for " .. name)
      os.exit(1)
    end
    local divTable = { attr = extendedAstNode.attr }
    local key
    for i, v in pairs(extendedAstNode.content) do
      if i % 2 == 1 then
        key = pandoc.utils.stringify(v)
      else
        divTable[key] = v
      end
    end
    return divTable
  end,

  build = function(name, nodeTable)
    if nodeTable == nil then
      -- if no name was supplied, we assume it comes from the 
      -- (then required) entry in the table.
      nodeTable = name
      name = pandoc.utils.stringify(nodeTable.class)
    else
      -- if a name was supplied, assume it overrides the
      -- entry in the table
      nodeTable.class = name
    end
    local handler = quarto.ast.resolveHandler(name)
    if handler == nil then
      print("ERROR: couldn't find a handler for " .. name)
      os.exit(1)
    end
    if handler.makePandocExtendedDiv then
      return handler.makePandocExtendedDiv(nodeTable)
    end

    local resultAttr
    local blocks = {}
    for name, value in pairs(nodeTable) do
      if name == "attr" then
        resultAttr = value
      else
        table.insert(blocks, pandoc.Str(name))
        table.insert(blocks, value)
      end                    
    end
    if resultAttr == nil then
      resultAttr = pandoc.Attr("", {}, attributes)
    end
    resultAttr.attributes[kExtendedAstTag] = name
    return pandoc.Div(blocks, resultAttr)
  end,
}

function constructExtendedAstHandlerState()
  local state = {
    namedHandlers = {},
    patternHandlers = {},
  }

  if preState ~= nil then
    preState.extendedAstHandlers = state
  end
  if postState ~= nil then
    postState.extendedAstHandlers = state
  end

  for i, handler in pairs(handlers) do
    quarto.ast.addHandler(handler)
  end
end

constructExtendedAstHandlerState()

