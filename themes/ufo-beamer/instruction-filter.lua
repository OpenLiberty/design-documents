-- Pandoc Lua filter: wrap ::: instruction divs in \begin{instruction}...\end{instruction}
-- so the LaTeX \excludecomment{instruction} in beamertheme.tex suppresses them on slides.
function Div(el)
  if el.classes:includes("instruction") then
    local open  = pandoc.RawBlock("latex", "\\begin{instruction}")
    local close = pandoc.RawBlock("latex", "\\end{instruction}")
    local blocks = {open}
    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end
    table.insert(blocks, close)
    return blocks
  end
end
