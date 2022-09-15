local extendedHandlers = {
  {
    class = "fancy-callout",
    name = "FancyCallout",
    extend = function(div)
      return {
        attr = div.attr,
        title = div.content[1],
        content = div.content[2]
      }
    end,
    retract = function(extendedNode)
      local blocks = {}
      table.insert(blocks, extendedNode.title)
      table.insert(blocks, extendedNode.content)
      extendedNode.attr.attributes["quarto-extended-ast-tag"] = nil
      return pandoc.Div(blocks, extendedNode.attr)
    end,
  },
}

for i, v in pairs(extendedHandlers) do
  for i, state in pairs({ preState, postState }) do
    if state ~= nil then
      state.extendedAstNodeHandlers[v.class] = v
    end
  end
end