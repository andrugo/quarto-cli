return {

  FancyCallout = {
    pre = function(callout)
      return "<fancy-callout>"
    end,
    value = function(callout, walk)
      walk("<title>")
      walk(callout.title)
      walk("</title>")
      walk("<content>")
      walk(callout.content)
      walk("</content>")
    end,
    post = function(callout)
      return "</fancy-callout>"
    end
  },

  -- equivalently
  -- FancyCallout = function(callout, walk)
  --   walk("<fancy-callout>")
  --   walk("<title>")
  --   walk(callout.title)
  --   walk("</title>")
  --   walk("<content>")
  --   walk(callout.content)
  --   walk("</content>")
  --   walk("</fancy-callout>")
  -- end,
}

