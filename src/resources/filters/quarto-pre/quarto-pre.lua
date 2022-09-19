-- quarto-pre.lua
-- Copyright (C) 2020 by RStudio, PBC

-- required version
PANDOC_VERSION:must_be_at_least '2.13'

-- global state
preState = {
  usingBookmark = false,
  usingTikz = false,
  results = {
    resourceFiles = pandoc.List({}),
    inputTraits = {}
  },
  file = nil,
  appendix = false,
  fileSectionIds = {},
  extendedAstNodeHandlers = {}
}

-- [import]
function import(script)
  local path = PANDOC_SCRIPT_FILE:match("(.*[/\\])")
  dofile(path .. script)
end

import("../ast/extended-nodes.lua")
import("../ast/make-extended-filters.lua")
import("../ast/parse.lua")
import("../common/base64.lua")
import("../common/colors.lua")
import("../common/debug.lua")
import("../common/error.lua")
import("../common/figures.lua")
import("../common/filemetadata.lua")
import("../common/format.lua")
import("../common/latex.lua")
import("../common/layout.lua")
import("../common/list.lua")
import("../common/log.lua")
import("../common/lunacolors.lua")
import("../common/map-or-call.lua")
import("../common/meta.lua")
import("../common/options.lua")
import("../common/pandoc.lua")
import("../common/paths.lua")
import("../common/refs.lua")
import("../common/string.lua")
import("../common/table.lua")
import("../common/tables.lua")
import("../common/theorems.lua")
import("../common/timing.lua")
import("../common/url.lua")
import("../common/wrapped-filter.lua")
import("bibliography-formats.lua")
import("book-links.lua")
import("book-numbering.lua")
import("callout.lua")
import("code-filename.lua")
import("content-hidden.lua")
import("engine-escape.lua")
import("figures.lua")
import("hidden.lua")
import("include-paths.lua")
import("input-traits.lua")
import("line-numbers.lua")
import("meta.lua")
import("options.lua")
import("output-location.lua")
import("outputs.lua")
import("panel-input.lua")
import("panel-layout.lua")
import("panel-sidebar.lua")
import("panel-tabset.lua")
import("profile.lua")
import("resourcefiles.lua")
import("results.lua")
import("shortcodes-handlers.lua")
import("shortcodes.lua")
import("table-captions.lua")
import("table-colwidth.lua")
import("table-rawhtml.lua")
import("theorems.lua")-- [/import]

initShortcodeHandlers()

local filterList = {
  { name = "init", filter = initOptions() },
  { name = "parseExtendedNodes", filter = parseExtendedNodes() },
  { name = "quartoExtendedUserFilters", filter = makeExtendedUserFilters("beforeQuartoFilters") },
  { name = "bibliographyFormats", filter = bibliographyFormats() },
  { name = "shortCodesBlocks", filter = shortCodesBlocks() } ,
  { name = "shortCodesInlines", filter = shortCodesInlines() },
  { name = "tableMergeRawHtml", filter = tableMergeRawHtml() },
  { name = "tableRenderRawHtml", filter = tableRenderRawHtml() },
  { name = "tableColwidthCell", filter = tableColwidthCell() },
  { name = "tableColwidth", filter = tableColwidth() },
  { name = "hidden", filter = hidden() },
  { name = "contentHidden", filter = contentHidden() },
  { name = "tableCaptions", filter = tableCaptions() },
  { name = "outputs", filter = outputs() },
  { name = "outputLocation", filter = outputLocation() },
  { name = "combined-figures-theorems-etc", filter = combineFilters({
    fileMetadata(),
    configProfile(),
    indexBookFileTargets(),
    bookNumbering(),
    includePaths(),
    resourceFiles(),
    figures(),
    theorems(),
    callout(),
    codeFilename(),
    lineNumbers(),
    engineEscape(),
    panelInput(),
    panelTabset(),
    panelLayout(),
    panelSidebar(),
    inputTraits()
  }) },
  { name = "combined-book-file-targets", filter = combineFilters({
    fileMetadata(),
    resolveBookFileTargets(),
  }) },
  { name = "quartoPreMetaInject", filter = quartoPreMetaInject() },
  { name = "writeResults", filter = writeResults() },
}

return capture_timings(filterList)
