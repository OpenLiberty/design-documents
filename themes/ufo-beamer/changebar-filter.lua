-- Pandoc Lua filter: changebar support for UFO slides
--
-- Block-level changes: wrap a div with \cbstart / \cbend
--
--   ::: changed          — magenta margin bar (modified content)
--   - Bullet that was added or modified
--   :::
--
--   ::: added            — magenta margin bar + light magenta background tint
--   - Entirely new bullet
--   :::
--
--   ::: deleted          — magenta margin bar; every bullet struck through and
--   - Bullet being removed    greyed, matching inline {.deleted} treatment
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
--
-- Mermaid diagram change annotations:
--
--   In a ```mermaid code block, annotation comments control per-node and
--   per-link styling that is injected only when ufo-changes metadata is true.
--
--   %% new-nodes: id1 id2 ...
--     → classDef ufoNew stroke:#EE538B,stroke-width:2px,stroke-dasharray:6,4
--       class id1,id2,... ufoNew
--
--   %% new-links: 0 1 2 ...   (0-based indices of arrow declarations)
--     → linkStyle 0,1,2,... stroke:#EE538B,stroke-width:2px
--
--   Both annotation lines are stripped from the emitted diagram in all builds.
--   The classDef/class/linkStyle lines are only injected when ufo-changes=true.

-- Whether --metadata ufo-changes=true was passed by the UFO Makefile.
local ufo_changes = false

function Meta(m)
  if m["ufo-changes"] and m["ufo-changes"] ~= false then
    ufo_changes = true
  end
end

-- Wrap a list of inlines in \ufoSout{...} raw latex.
-- \ufoSout is defined in beamertheme.tex and is a no-op unless \ufochangestrue.
local function sout_inlines(inlines)
  local result = {pandoc.RawInline("latex", "\\ufoSout{")}
  for _, i in ipairs(inlines) do
    table.insert(result, i)
  end
  table.insert(result, pandoc.RawInline("latex", "}"))
  return result
end

-- Escape special LaTeX characters in a plain string for use in \texttt{}.
local function latex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("{",  "\\{")
  s = s:gsub("}",  "\\}")
  s = s:gsub("#",  "\\#")
  s = s:gsub("%$", "\\$")
  s = s:gsub("%%", "\\%%")
  s = s:gsub("&",  "\\&")
  s = s:gsub("_",  "\\_")
  s = s:gsub("%^", "\\^{}")
  s = s:gsub("~",  "\\~{}")
  s = s:gsub("<",  "\\textless{}")
  s = s:gsub(">",  "\\textgreater{}")
  return s
end

-- Walk a list of blocks and apply \ufoSout to every Para, Plain, CodeBlock,
-- and BulletList/OrderedList item, matching inline {.deleted} style.
local function apply_sout_to_blocks(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    if b.t == "Para" or b.t == "Plain" then
      local newb = b:clone()
      newb.content = sout_inlines(b.content)
      table.insert(out, newb)
    elseif b.t == "CodeBlock" then
      -- Wrap each line of the code block in \ufoSout{\texttt{...}} so the
      -- strikethrough matches the rest of the deleted block content.
      local lines = {}
      for line in (b.text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(lines, "\\ufoSout{\\texttt{" .. latex_escape(line) .. "}}")
      end
      table.insert(out, pandoc.RawBlock("latex",
        "\\vspace{0.3em}\\noindent " .. table.concat(lines, "\\\\") .. "\\vspace{0.3em}"))
    elseif b.t == "BulletList" or b.t == "OrderedList" then
      local items = {}
      local list_content = (b.t == "BulletList") and b.content or b.content
      for _, item in ipairs(list_content) do
        table.insert(items, apply_sout_to_blocks(item))
      end
      local newb = b:clone()
      newb.content = items
      table.insert(out, newb)
    else
      table.insert(out, b)
    end
  end
  return out
end

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

  if el.classes:includes("added") then
    local open  = pandoc.RawBlock("latex", "\\cbstart{}\\begin{ufoAddedBlock}")
    local close = pandoc.RawBlock("latex", "\\end{ufoAddedBlock}\\cbend{}")
    local blocks = {open}
    for _, b in ipairs(el.content) do
      table.insert(blocks, b)
    end
    table.insert(blocks, close)
    return blocks
  end

  if el.classes:includes("deleted") then
    -- Apply \sout to every paragraph/item inline at the AST level so the
    -- strikethrough matches inline {.deleted} exactly, with no LaTeX
    -- environment tricks required.
    local struck = apply_sout_to_blocks(el.content)
    local open  = pandoc.RawBlock("latex", "\\cbstart{}\\begin{ufoDeletedBlock}")
    local close = pandoc.RawBlock("latex", "\\end{ufoDeletedBlock}\\cbend{}")
    local blocks = {open}
    for _, b in ipairs(struck) do
      table.insert(blocks, b)
    end
    table.insert(blocks, close)
    return blocks
  end
end

function Span(el)
  -- {.changed} — single inline margin bar wrapping a {.deleted}+{.added} pair.
  -- Uses \cbistart/\cbiend (vadjust-based) for correct single-line height.
  -- Child spans are already processed by Pandoc before the parent runs,
  -- so we strip their \cbistart{}/\cbiend{} tokens from child RawInlines and
  -- replace with a single outer pair.
  if el.classes:includes("changed") then
    local inlines = {pandoc.RawInline("latex", "\\cbistart{}")}
    for _, i in ipairs(el.content) do
      -- Strip \cbistart{} prefix and \cbiend{} suffix baked into child spans.
      if i.t == "RawInline" and i.format == "latex" then
        local stripped = i.text
          :gsub("^\\cbistart{}", "")
          :gsub("\\cbiend{}$",   "")
        if stripped ~= "" then
          table.insert(inlines, pandoc.RawInline("latex", stripped))
        end
      else
        table.insert(inlines, i)
      end
    end
    table.insert(inlines, pandoc.RawInline("latex", "\\cbiend{}"))
    return inlines
  end

  if el.classes:includes("added") then
    local inlines = {pandoc.RawInline("latex", "\\cbistart{}\\ufoAdded{")}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, pandoc.RawInline("latex", "}\\cbiend{}"))
    return inlines
  end

  if el.classes:includes("deleted") then
    local inlines = {pandoc.RawInline("latex", "\\cbistart{}\\ufoSout{")}
    for _, i in ipairs(el.content) do
      table.insert(inlines, i)
    end
    table.insert(inlines, pandoc.RawInline("latex", "}\\cbiend{}"))
    return inlines
  end
end

-- Counter for unique PNG filenames when multiple diagrams appear in one deck.
local mermaid_count = 0

-- ── Built-in palette — all named colours from beamertheme.tex ─────────────────
-- Authors can reference these as $name in classDef / style / linkStyle lines.
-- The %% @palette line can add or override entries for a single diagram.
local BUILTIN_PALETTE = {
  -- Theme colours
  ufonavydark  = "#20203E",
  ufoteal      = "#4C577D",
  ufolime      = "#C6E000",
  ufopagenumber= "#BAC0D4",
  ufochanged   = "#EE538B",
  ufolink      = "#0066CC",
  -- CVD-safe categorical palette (IBM / Wong 2011)
  cvdgold      = "#ffb000",
  cvdorange    = "#fe6100",
  cvdmagenta   = "#dc267f",
  cvdviolet    = "#785ef0",
  cvdblue      = "#648fff",
}

-- Apply palette substitutions: replace $name with the hex value.
-- Unknown $names are left unchanged so Mermaid can catch the error.
local function apply_palette(text, palette)
  return (text:gsub("%$([%w_]+)", function(name)
    return palette[name] or ("$" .. name)
  end))
end

-- ── Default themeVariables init block ─────────────────────────────────────────
-- Injected before any diagram that does NOT already contain %%{init.
-- Sets cScale0-4 to the CVD palette and global defaults to theme colours.
local DEFAULT_INIT = '%%{init: {"theme": "base", "themeVariables": {' ..
  '"primaryColor": "#648fff",' ..   -- cvdblue  — default node fill
  '"primaryBorderColor": "#4C577D",' .. -- ufoteal — node border
  '"primaryTextColor": "#20203E",' ..   -- ufonavydark — node text
  '"secondaryColor": "#785ef0",' ..     -- cvdviolet — secondary nodes
  '"tertiaryColor": "#ffb000",' ..      -- cvdgold   — tertiary nodes
  '"lineColor": "#20203E",' ..          -- ufonavydark — arrows
  '"clusterBkg": "#f5f5ff",' ..         -- near-white violet tint — subgraphs
  '"clusterBorder": "#4C577D",' ..      -- ufoteal
  '"cScale0": "#648fff",' ..            -- cvdblue
  '"cScale1": "#785ef0",' ..            -- cvdviolet
  '"cScale2": "#ffb000",' ..            -- cvdgold
  '"cScale3": "#fe6100",' ..            -- cvdorange
  '"cScale4": "#dc267f"' ..             -- cvdmagenta
  '}} }%%'

function CodeBlock(el)
  -- Only process mermaid code blocks.
  if not el.classes:includes("mermaid") then return nil end

  local new_nodes = nil  -- space-separated node IDs
  local new_links = nil  -- space-separated 0-based link indices
  local palette   = {}   -- per-diagram palette overrides from %% @palette
  local css_lines = {}   -- per-diagram CSS lines from %% @css annotations
  local clean_lines = {}
  local has_init = false

  -- Copy built-in palette as the starting point for this diagram.
  for k, v in pairs(BUILTIN_PALETTE) do palette[k] = v end

  for line in (el.text .. "\n"):gmatch("([^\n]*)\n") do
    local nodes   = line:match("^%s*%%%%%s*new%-nodes:%s*(.+)$")
    local links   = line:match("^%s*%%%%%s*new%-links:%s*(.+)$")
    local pal_str = line:match("^%s*%%%%%s*@palette%s+(.+)$")
    local css_str = line:match("^%s*%%%%%s*@css%s+(.*)$")
    if nodes then
      new_nodes = nodes:match("^%s*(.-)%s*$")
    elseif links then
      new_links = links:match("^%s*(.-)%s*$")
    elseif pal_str then
      -- Parse space-separated key=value pairs into the palette table.
      for pair in pal_str:gmatch("%S+") do
        local k, v = pair:match("^([%w_]+)=(.+)$")
        if k then palette[k] = v end
      end
    elseif css_str ~= nil then
      -- Accumulate verbatim CSS lines (palette $vars substituted later).
      table.insert(css_lines, css_str)
    else
      if line:match("^%s*%%%%{init") then has_init = true end
      table.insert(clean_lines, line)
    end
  end

  local diagram = table.concat(clean_lines, "\n")

  -- Inject default themeVariables when the author hasn't supplied their own.
  if not has_init then
    diagram = DEFAULT_INIT .. "\n" .. diagram
  end

  -- Apply $name palette substitutions throughout the diagram.
  diagram = apply_palette(diagram, palette)

  -- Inject change styling when ufo-changes metadata is active.
  if ufo_changes then
    local injected = {}
    if new_nodes and new_nodes ~= "" then
      -- Magenta dashed border ring matching the TikZ convention.
      table.insert(injected,
        "classDef ufoNew stroke:#EE538B,stroke-width:2px,stroke-dasharray:6,4,fill:#fff0f5")
      -- Convert space-separated IDs to comma-separated for class directive.
      local ids = new_nodes:gsub("%s+", ",")
      table.insert(injected, "class " .. ids .. " ufoNew")
    end
    if new_links and new_links ~= "" then
      -- Magenta arrows matching the TikZ ufochanged colour.
      local indices = new_links:gsub("%s+", ",")
      table.insert(injected,
        "linkStyle " .. indices .. " stroke:#EE538B,stroke-width:2px")
    end
    if #injected > 0 then
      diagram = diagram .. "\n" .. table.concat(injected, "\n")
    end
  end

  -- Render the diagram to PNG via mmdc and return a Para([Image(...)]).
  -- Falls back to keeping the code block unchanged if mmdc is not available.
  mermaid_count = mermaid_count + 1
  local png_path = os.tmpname() .. "-ufo-mermaid-" .. mermaid_count .. ".png"

  -- Write diagram source to a temp file (mmdc doesn't read stdin reliably).
  local src_path = os.tmpname() .. ".mmd"
  local f = io.open(src_path, "w")
  if not f then return nil end
  f:write(diagram)
  f:close()

  -- Locate mmdc: prefer the system-installed @mermaid-js/mermaid-cli (v12+),
  -- fall back to the one bundled with the old mermaid-filter package.
  local mmdc = "mmdc"
  local system_mmdc = "/opt/homebrew/bin/mmdc"
  local legacy_mmdc = "/opt/homebrew/lib/node_modules/mermaid-filter/node_modules/.bin/mmdc"
  local f = io.open(system_mmdc, "r")
  if f then
    f:close()
    mmdc = system_mmdc
  else
    f = io.open(legacy_mmdc, "r")
    if f then f:close(); mmdc = legacy_mmdc end
  end

  -- mmdc ≥12 uses --size instead of -w; fall back to -w for older binaries.
  -- MERMAID_FILTER_WIDTH is still honoured for backwards compatibility.
  local size = os.getenv("MERMAID_FILTER_WIDTH") or "2400"

  -- Build optional -C <cssfile> flag when %% @css annotations were present.
  local css_flag = ""
  local css_path = nil
  if #css_lines > 0 then
    css_path = os.tmpname() .. "-ufo-mermaid.css"
    local css_src = apply_palette(table.concat(css_lines, "\n"), palette)
    local cf = io.open(css_path, "w")
    if cf then
      cf:write(css_src .. "\n")
      cf:close()
      css_flag = string.format(" -C %s", css_path)
    end
  end

  local cmd = string.format(
    '%s -i %s -o %s --size %s -b transparent -q%s 2>/dev/null',
    mmdc, src_path, png_path, size, css_flag)
  os.execute(cmd)
  os.remove(src_path)
  if css_path then os.remove(css_path) end

  -- Check the PNG was produced.
  local check = io.open(png_path, "r")
  if not check then
    -- mmdc failed — fall back to a visible error placeholder.
    return pandoc.Para({pandoc.Str("[Mermaid render failed]")})
  end
  check:close()

  -- Emit \includegraphics wrapped in \begin{center}...\end{center} so the diagram
  -- is horizontally centred on the slide regardless of its natural width.
  -- width=\linewidth, height=\textheight-3.1cm (content area below frametitle),
  -- keepaspectratio — LaTeX picks whichever dimension is the binding constraint,
  -- so wide diagrams fill the width and tall diagrams fit the content height.
  -- Neither dimension is ever stretched or squashed.
  local latex = string.format(
    "\\includegraphics[width=\\linewidth,height=\\dimexpr\\textheight-3.1cm\\relax,keepaspectratio]{%s}",
    png_path)
  return {
    pandoc.RawBlock("latex", "\\begin{center}"),
    pandoc.Para({pandoc.RawInline("latex", latex)}),
    pandoc.RawBlock("latex", "\\end{center}"),
  }
end
