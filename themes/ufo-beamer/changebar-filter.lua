-- Pandoc Lua filter: changebar support for UFO slides
--
-- Block-level changes: wrap a ::: changed div with \cbstart / \cbend
--
--   ::: changed
--   - Bullet that was added or modified
--   :::
--
-- Inline changes on a single run of text:
--
--   [added text]{.added}      → \ufoAdded{added text}
--                                (light magenta highlight box, defined in beamertheme.tex)
--
--   [deleted text]{.deleted}  → \sout{deleted text}
--                                (strikethrough via ulem; no margin bar — single-line
--                                 \cbstart/\cbend produces zero-height bars)
--
-- \cbstart / \cbend are still used at block level (Div handler above).

function Div(el)
  if el.classes:includes("changed") then
    local open  = pandoc.RawBlock("latex", "\\cbstart{}")
    local close = pandoc.RawBlock("latex", "\\cbend{}")
    local blocks = {open}
    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end
    table.insert(blocks, close)
    return blocks
  end
end

function Span(el)
  if el.classes:includes("added") then
    -- Highlight added text with a light magenta colorbox.
    -- \cbstart/\cbend produced zero-height margin bars for single-line spans
    -- so we use \ufoAdded{} for a visible inline highlight instead.
    local open  = pandoc.RawInline("latex", "\\ufoAdded{")
    local close = pandoc.RawInline("latex", "}")
    local inlines = {open}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, close)
    return inlines
  end

  if el.classes:includes("deleted") then
    -- Strike through deleted text; no margin bar (same zero-height issue).
    local open  = pandoc.RawInline("latex", "\\sout{")
    local close = pandoc.RawInline("latex", "}")
    local inlines = {open}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, close)
    return inlines
  end
end
