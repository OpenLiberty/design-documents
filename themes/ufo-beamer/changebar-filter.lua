-- Pandoc Lua filter: changebar support for UFO slides
--
-- Block-level additions: wrap a ::: changed div with \cbstart / \cbend
--
--   ::: changed
--   - Bullet that was added or modified
--   :::
--
-- Block-level deletions: wrap a ::: deleted div with \ufoDeletedBlock
--
--   ::: deleted
--   - Bullet that was removed
--   :::
--
--   In changebar builds (\ufochangestrue) the bullet is shown struck through.
--   In final builds the block is silently discarded.
--
-- Inline changes on a single run of text:
--
--   [added text]{.added}      → \ufoAdd{added text}
--                                (light magenta highlight box in review builds,
--                                 plain text in final builds; defined in beamertheme.tex)
--
--   [deleted text]{.deleted}  → \ufoDel{deleted text}
--                                (strikethrough in review builds, silent in final builds;
--                                 defined in beamertheme.tex)
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

  if el.classes:includes("deleted") then
    local open  = pandoc.RawBlock("latex", "\\begin{ufoDeletedBlock}")
    local close = pandoc.RawBlock("latex", "\\end{ufoDeletedBlock}")
    -- Wrap the inlines of each Plain/Para item directly in \ufoDel{} raw LaTeX.
    -- (Creating a {.deleted} Span here and relying on the Span handler below
    -- does not work — the Div handler fires before Span in the same pass.)
    local function strikeitem(iblock)
      local newInlines = {pandoc.RawInline("latex", "\\ufoDel{")}
      for _, i in ipairs(iblock.content) do
        table.insert(newInlines, i)
      end
      table.insert(newInlines, pandoc.RawInline("latex", "}"))
      if iblock.t == "Plain" then return pandoc.Plain(newInlines)
      else                        return pandoc.Para(newInlines)
      end
    end
    local function strikeblock(b)
      if b.t == "BulletList" then
        local newItems = {}
        for _, item in ipairs(b.content) do
          local newItem = {}
          for _, iblock in ipairs(item) do
            if iblock.t == "Plain" or iblock.t == "Para" then
              table.insert(newItem, strikeitem(iblock))
            else
              table.insert(newItem, iblock)
            end
          end
          table.insert(newItems, newItem)
        end
        return pandoc.BulletList(newItems)
      end
      return b
    end
    local blocks = {open}
    for _, b in ipairs(el.content) do
      table.insert(blocks, strikeblock(b))
    end
    table.insert(blocks, close)
    return blocks
  end
end

function Span(el)
  if el.classes:includes("added") then
    local open  = pandoc.RawInline("latex", "\\ufoAdd{")
    local close = pandoc.RawInline("latex", "}")
    local inlines = {open}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, close)
    return inlines
  end

  if el.classes:includes("deleted") then
    local open  = pandoc.RawInline("latex", "\\ufoDel{")
    local close = pandoc.RawInline("latex", "}")
    local inlines = {open}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, close)
    return inlines
  end
end
