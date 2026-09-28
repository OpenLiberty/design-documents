-- table-filter.lua — Pandoc Lua filter for UFO Beamer slides
--
-- Converts Pandoc pipe tables to raw LaTeX \tabular instead of \longtable.
-- \longtable is incompatible with Beamer frames: it tries to span pages,
-- misreads \linewidth inside a frame, and breaks inside block environments.
--
-- Columns use natural l/c/r widths — just wide enough for the content —
-- and the table is centred on the slide with \begin{center}...\end{center}.
--
-- Lua API for Pandoc 3.x Table element:
--   tbl.colspecs   — array of {alignment_string, width_number_or_nil}
--                    alignment_string: "AlignLeft"|"AlignRight"|"AlignCenter"|"AlignDefault"
--   tbl.head       — TableHead userdata with .rows (array of Row userdata)
--   tbl.bodies     — array of TableBody userdata, each with .body (array of Row userdata)
--   Row userdata   — .cells (array of Cell userdata)
--   Cell userdata  — .contents (array of Block elements)
--
-- Cell content is rendered via pandoc.write so inline elements
-- (bold, italic, inline code, etc.) are emitted as correct LaTeX.
--
-- NOTE: string.gsub returns (string, count). Always capture into a local
-- variable before passing to table.insert — otherwise Lua sees the count
-- as a position argument and errors with "number expected, got string".

-- Render a list of Pandoc block elements to a LaTeX string.
local function blocks_to_latex(blocks)
  if #blocks == 0 then return "" end
  local doc = pandoc.Pandoc(blocks)
  local tex = pandoc.write(doc, "latex")
  local result = tex:gsub("%s+$", "")
  return result
end

-- Map a Pandoc alignment string to a LaTeX column letter.
local function align_letter(align)
  if align == "AlignCenter" then
    return "c"
  elseif align == "AlignRight" then
    return "r"
  else
    return "l"   -- AlignLeft or AlignDefault
  end
end

function Table(tbl)
  local colspecs = tbl.colspecs   -- array of {alignment_string, width_or_nil}

  -- Build column preamble: natural-width l/c/r columns, no outer padding.
  local col_preamble = "@{}"
  for _, cs in ipairs(colspecs) do
    col_preamble = col_preamble .. align_letter(cs[1])
  end
  col_preamble = col_preamble .. "@{}"

  local lines = {}
  table.insert(lines, "\\begin{center}")
  table.insert(lines, "\\rowcolors{2}{ufoteal!10}{white}")
  table.insert(lines, "\\begin{tabular}{" .. col_preamble .. "}")
  table.insert(lines, "\\toprule")

  -- Header rows (tbl.head.rows).
  if tbl.head and #tbl.head.rows > 0 then
    for _, row in ipairs(tbl.head.rows) do
      local cells = {}
      for _, cell in ipairs(row.cells) do
        local content = blocks_to_latex(cell.contents)
        if content ~= "" then
          table.insert(cells, "\\textbf{" .. content .. "}")
        else
          table.insert(cells, "")
        end
      end
      table.insert(lines, table.concat(cells, " & ") .. " \\\\")
    end
    table.insert(lines, "\\midrule")
  end

  -- Body rows (tbl.bodies[i].body is the array of data rows).
  for _, tbody in ipairs(tbl.bodies) do
    for _, row in ipairs(tbody.body) do
      local cells = {}
      for _, cell in ipairs(row.cells) do
        table.insert(cells, blocks_to_latex(cell.contents))
      end
      table.insert(lines, table.concat(cells, " & ") .. " \\\\")
    end
  end

  table.insert(lines, "\\bottomrule")
  table.insert(lines, "\\end{tabular}")
  table.insert(lines, "\\end{center}")

  return pandoc.RawBlock("latex", table.concat(lines, "\n"))
end
