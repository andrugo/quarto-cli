-- [import]
function import(script)
  local path = PANDOC_SCRIPT_FILE:match("(.*[/\\])")
  dofile(path .. script)
end

postState = {}

import("make-extended-filters.lua")
import("extended-nodes.lua")
import("../common/wrapped-filter.lua")

return makeWrappedFilter(param("custom-writer"), function(handlers)
  -- FIXME handle lists of filters
end)