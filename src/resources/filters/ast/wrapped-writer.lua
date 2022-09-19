postState = {}

function import(script)
  local path = PANDOC_SCRIPT_FILE:match("(.*[/\\])")
  dofile(path .. script)
end

-- [import]
import("../common/map-or-call.lua")
import("../common/wrapped-filter.lua")
import("extended-nodes.lua")
import("make-extended-filters.lua")

local resultingStrs = {}

-- wrapped writers do not support filter lists
ourWrappedWriter = makeWrappedFilter(param("custom-writer"), function(handler)

  local contentHandler = function(el)
    return el.content
  end
  local itemsHandler = function(el)
    return el.items
  end

  local bottomUpWalkers = {
    Pandoc = function(doc)
      local result = {}
      if doc.blocks then
        for i, block in pairs(doc.blocks) do
          table.insert(result, block)
        end
      end
      if doc.meta then
        table.insert(result, doc.meta)
      end
      return result
    end,
    BlockQuote = contentHandler,
    BulletList = itemsHandler,

    -- unclear what to do here from https://pandoc.org/lua-filters.html#type-definitionlist
    -- DefinitionList = function(element)
    -- end,

    Div = contentHandler,
    Header = contentHandler,
    LineBlock = contentHandler,
    OrderedList = itemsHandler,
    Para = contentHandler,
    Plain = contentHandler,

    -- we don't break Table up because it is
    -- almost certainly the case that handling
    -- it correctly requires access to the full object
    -- in a custom handler,

    Cite = function(element)
      local result = {}
      for i, block in pairs(element.content) do
        table.insert(result, block)
      end
      for i, block in pairs(element.citations) do
        table.insert(result, block)
      end
    end,

    Emph = contentHandler,
    Image = function(element)
      return element.caption
    end,
    Link = contentHandler,
    Note = contentHandler,
    Quoted = contentHandler,
    SmallCaps = contentHandler,
    Span = contentHandler,
    Strikeout = contentHandler,
    Strong = contentHandler,
    Subscript = contentHandler,
    Superscript = contentHandler,
    Underline = contentHandler,

    -- default simple behavior
    Str = function(s)
      return { s.text }
    end,
    Space = function() return { " " } end,
    LineBreak = function() return { "\n" } end,
    SoftBreak = function() return { "\n" } end,
  }
  setmetatable(bottomUpWalkers, {
    __index = function(_, key)
      return function() return {} end
    end
  })  

  function handleBottomUpResult(v)
    if type(v) == "string" then
      table.insert(resultingStrs, v)
      return nil
    elseif type(v) == "userdata" then
      return bottomUp(v)
    else
      return nil
    end
  end

  function bottomUp(node)
    if type(node) == "string" then
      table.insert(resultingStrs, node)
      return nil
    end

    local nodeHandler
    local t

    -- the second check is needed because pandoc's Meta is a table as well
    if type(node) == "table" and pandoc.utils.type(node) == "table" then
      local astTag = node.attr and node.attr.attributes["quarto-extended-ast-tag"]
      local astHandler = quarto.ast.resolveHandler(astTag)
      nodeHandler = astHandler and handler[astHandler.astName] and handler[astHandler.astName].handle
      -- if we had a table as a result but we don't know how to write it,
      -- we then build it back to a div as a last-ditch resort
      if nodeHandler == nil then
        node = quarto.ast.build(node)
        t = node.t or pandoc.utils.type(node)
      end
      -- postcondition: nodeHandler ~= nil and type(node) == table or type(node) == userdata and t has been set
    elseif type(node) == "userdata" then
      t = node.t or pandoc.utils.type(node)
      -- try to find quarto extended AST tag
      local astTag = t == "Div" and node.attr and node.attr.attributes["quarto-extended-ast-tag"]
      local astHandler = quarto.ast.resolveHandler(astTag)
      nodeHandler = astHandler and handler[astHandler.astName] and handler[astHandler.astName].handle
      -- we have a handler and we know to write it:
      -- convert to table for the handler
      if nodeHandler ~= nil then
        node = quarto.ast.unbuild(node)
      end
      -- postcondition: nodeHandler ~= nil and type(node) == table or type(node) == userdata and t has been set
    end
    -- postcondition: nodeHandler ~= nil and type(node) == table or type(node) == userdata and t has been set

    -- at this point, we have 
    --    type(node) == "table"    and nodeHandler ~= nil    (yes custom writer entry for extended ast)
    -- or type(node) == "userdata" and nodeHandler == nil (no  custom writer entry for extended ast)

    if nodeHandler == nil then
      -- no extended ast, hence t has been set
      nodeHandler = handler[t] and handler[t].handle

      if nodeHandler == nil then
        -- no handler, just walk the internals in some default order
        for i,v in pairs(bottomUpWalkers[t](node)) do
          local inner = bottomUp(v)
          if inner then
            mapOrCall(handleBottomUpResult, inner)
          end
        end

        return nil
      end

      -- postcondition: we found handler
    end
    -- postcondition: we found handler

    -- use handler
    if type(nodeHandler) == "function" then
      nodeHandler = {
        value = nodeHandler
      }
    end
    if nodeHandler.pre then
      table.insert(resultingStrs, nodeHandler.pre(node, bottomUp))
    end
    if nodeHandler.value then
      node = nodeHandler.value(node, bottomUp)
      if node then
        mapOrCall(handleBottomUpResult, node)
      end
    end
    if nodeHandler.post then
      table.insert(resultingStrs, nodeHandler.post(node, bottomUp))
    end
    return nil
  end

  local wrappedFilter = {
    traverse = 'topdown',
    Pandoc = function(doc)
      bottomUp(doc)
      return doc, false
    end
  }
  return wrappedFilter
end)

function Writer(docs, options)
  docs:walk(ourWrappedWriter)

  local finalResult = table.concat(resultingStrs, "") .. "\n"
  return finalResult
end
