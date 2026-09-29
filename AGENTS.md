# UFO — Agent Instructions

This file provides agent-actionable conventions for working in this repository.
Read it before creating, editing, or building any UFO.

---

## Environment setup

Before building any UFO, verify the required tools are installed. If a tool is
missing or out of date, guide the user to install it using the instructions below.

### Required tools

| Tool | Minimum version | Check command | Install |
|---|---|---|---|
| **pandoc** | 3.0 | `pandoc --version` | `brew install pandoc` |
| **XeLaTeX** | any recent TeXLive | `xelatex --version` | `brew install --cask mactex-no-gui` |
| **Trebuchet MS** + **Arial** | — | `fc-list \| grep -i trebuchet` | macOS: built-in · Linux: `apt install ttf-mscorefonts-installer` |
| **Python 3** | 3.8 | `python3 --version` | `brew install python` |
| **Node.js** | 18 | `node --version` | `brew install node` |
| **@mermaid-js/mermaid-cli** (`mmdc`) | 12.0.0 | `mmdc --version` | `npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli` |

### Quick environment check

Run from anywhere in the repo:

```bash
pandoc --version | head -1
xelatex --version | head -1
mmdc --version
python3 --version
node --version
```

### Installing `mmdc` (Mermaid CLI)

`mmdc` is required for rendering Mermaid diagrams in slides. It uses Puppeteer
(headless Chromium) internally — the `--allow-scripts=puppeteer` flag is needed
to let Puppeteer download its bundled browser on first install:

```bash
npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli
mmdc --version   # should print 12.x.x or higher
```

On **Linux**, Puppeteer's Chromium needs these system libraries:

```bash
sudo apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libxkbcommon0 libxcomposite1 libxdamage1 \
  libxfixes3 libxrandr2 libgbm1 libasound2
```

If `mmdc` is not installed, the build will still succeed but any `mermaid` code
blocks will be replaced with `[Mermaid render failed]` placeholder text in the PDF.

---

## Repository layout

```
ufo/
├── themes/ufo-beamer/       ← shared theme — never edit per-UFO
│   ├── ufo-beamer.mk        ← shared Makefile rules (included by every UFO)
│   ├── beamertheme.tex      ← Beamer theme, colours, changebar commands
│   ├── changebar-filter.lua ← Pandoc filter for change markup
│   ├── instruction-filter.lua
│   ├── table-filter.lua     ← Pandoc filter: converts pipe tables to \tabular
│   ├── epics.sh             ← epic validation + slug/link generation
│   ├── epic-prefixes.conf   ← recognised epic ID prefixes
│   ├── check-overflow.py    ← post-build overflow checker
│   ├── generate-handouts.py ← notes/handout/speakernotes generator
│   ├── *.png                ← background images
│   └── examples/
│       ├── changebars/      ← worked changebar example (build to see output)
│       ├── mermaid-diagrams/ ← Mermaid diagram type examples
│       └── tables/          ← pipe table examples (natural-width \tabular)
├── templates/ufo/           ← copy this to create a new UFO
├── output/                  ← all built PDFs land here (gitignored)
└── <issue>-<feature>/       ← one directory per submitted UFO
```

---

## Theme examples

Each subdirectory under `themes/ufo-beamer/examples/` is a self-contained,
buildable UFO that demonstrates a specific theme capability. Run `make slides`
inside any example directory to build its PDF.

| Directory         | Demonstrates |
|:------------------|:-------------|
| `changebars/`     | All `::: changed` / `::: added` / `::: deleted` / `{.added}` / `{.deleted}` markup patterns |
| `mermaid-diagrams/` | All Mermaid diagram types (flowchart, swimlane, sequence, state, timeline, architecture, packet) |
| `tables/`         | Pipe table patterns: basic, centre-aligned, mixed alignment, tables in changebars, two tables per slide |

### Example content conventions

Examples use fictional, product-neutral vocabulary so they remain readable
outside the context of any real feature. Follow the same conventions when
adding new examples:

- **Feature**: `acme-gizmo-2.0` (or `acme-doodad`, `acme-widget`, `acme-gadget`)
- **Config element**: `<acme-gizmo propagation="…"/>`
- **Propagation modes**: `always` / `conditional` / `never`
- **Policy assertion**: `<acme:GizmoSupport>`
- **Exception**: `GizmoException`
- **Actors**: `A. N. Engineer` (architect), `OL-33070` (epic)
- **Component names**: `GizmoInterceptor`, `PropagationMode`, `PolicyEngine`, `GizmoConfig`

Do **not** use real Open Liberty feature names, real OASIS/W3C namespace URIs,
or technology-specific terminology (JAX-WS, WS-AT, Jakarta, etc.) in examples.

---

## Creating a new UFO

1. Copy the template: `cp -r templates/ufo <issue>-<feature>` (e.g. `33070-conditional-wsat`)
2. Edit `slides/00-title.md` front matter — see [Front matter](#front-matter) below.
3. Fill in `slides/01-design-thinking.md` through `slides/03-quality.md`.
4. Build from inside the UFO directory: `make slides`
5. Commit only the UFO directory (not `output/`).

---

## Front matter

Every UFO's `slides/00-title.md` must have:

```yaml
---
title: "Short Feature Name"
architect: "Full Name"
ufo-date: "2025-Q3"
epics: "OL-33070"
date: ""
---
```

- `title` — used on the title slide and in the output filename (downcased, hyphenated)
- `architect` — shown as "Architect: …" in the author block
- `ufo-date` — shown as "Date: …" (`date` must be left blank)
- `epics` — comma-separated; each must match a known prefix (see below)
- Do **not** use `<` or `>` in `title` — Pandoc treats them as HTML

### Epic prefixes

| Prefix | Tracker |
|---|---|
| `OL-nnnnn` | github.com/OpenLiberty/open-liberty |
| `CL-nnnnn` | github.ibm.com/websphere/WS-CD-Open |
| `MORE-nnnnn` | github.ibm.com/websphere/project-london |

To add a prefix, edit `themes/ufo-beamer/epic-prefixes.conf`.

---

## UFO Makefile

Every UFO Makefile must set `SOURCES` then include the shared rules:

```makefile
SOURCES = $(SLIDES_DIR)/00-title.md \
          $(SLIDES_DIR)/01-design-thinking.md \
          $(SLIDES_DIR)/02-externals-design.md \
          $(SLIDES_DIR)/03-quality.md

# Uncomment for a revised UFO — activates change key, -with-changes filename suffix,
# and ufo-changes metadata for Mermaid/TikZ change annotations:
# WITH_CHANGES = true

include $(shell git rev-parse --show-toplevel)/themes/ufo-beamer/ufo-beamer.mk
```

`WITH_CHANGES = true` is a single-line shorthand that sets `EXTRA_VARS_TEX`,
`PDF_VARIANT`, and `PANDOC_EXTRA_META` together. They can still be overridden
individually if needed. The `include` path uses `git rev-parse --show-toplevel`
so it resolves correctly regardless of where the UFO directory sits in the repo.

---

## Build targets

Run from inside the UFO directory:

| Command | Output |
|---|---|
| `make` or `make slides` | Slides PDF → `output/<name>-slides.pdf` |
| `make all` | All four: slides, notes, handout, speakernotes |
| `make notes` | Speaker notes (no slide image) |
| `make handout` | Slide image + notes per page |
| `make speakernotes` | Slide image + instruction boxes + notes |
| `make clean` | Removes `build/` and this UFO's PDFs from `output/` |

PDFs always land in the repo-level `output/` directory (gitignored). Never commit PDFs.

---

## Marking up changes (revised UFOs)

Use these markup patterns to highlight what changed for reviewers.
See `themes/ufo-beamer/examples/changebars/` for a rendered example
(run `make` there to build the PDF).

### Changed bullet or paragraph — magenta margin bar

```markdown
::: changed
- This bullet was modified or added
:::
```

### Entirely new block — magenta margin bar + light magenta background tint

```markdown
::: added
- This bullet did not exist in the previous revision
:::
```

Matches the inline `{.added}` colorbox highlight, applied to the whole block.

### Removed block — magenta margin bar + per-bullet strikethrough, greyed text

```markdown
::: deleted
- This bullet is being removed
:::
```

Matches the inline `{.deleted}` strikethrough — every bullet in the block is struck through.

### Added inline text — light magenta highlight

```markdown
The attribute now accepts [`conditional`]{.added} as a value.
```

### Deleted inline text — strikethrough

```markdown
Calls to [`all`]{.deleted} [`opted-in`]{.added} endpoints are affected.
```

### Whole new TikZ diagram — explicit margin bar

Draw a vertical rule just outside the leftmost content at a fixed x coordinate,
wrapped in `\ifufochanges` so it is suppressed in non-revision builds:

```latex
\ifufochanges
  \draw[ufochanged, line width=2.5pt, line cap=round]
    (-5.0, 0.35) -- (-5.0, -2.55);
\fi
```

### New node in an existing TikZ diagram — dashed highlight ring

Draw a `fit` node as a dashed magenta ring around the new node, after it:

```latex
\node[draw=ufochanged, line width=1.8pt, dashed,
      dash pattern=on 4pt off 2pt,
      rounded corners=5pt, fill=none,
      fit=(newnode), inner sep=4pt] {};
```

### New path in an existing TikZ diagram — magenta arrow with halo glow

Define the `newarrow` style in the `tikzpicture` options:

```latex
newarrow/.style={draw=ufochanged, -latex, thick,
                 postaction={draw=ufochanged, line width=5pt, opacity=0.18}}
```

Then use `\draw[newarrow]` for new paths.

### Change key on the title slide

Set `EXTRA_VARS_TEX = \ufochangestrue` in the UFO Makefile before the `include`.
This draws a "Changes detected!" indicator with a legend in the title slide's open beam area.

### Rules

- `::: changed`, `::: added`, and `::: deleted` work at block level (bullets, paragraphs). Do not use them to wrap raw `{=latex}` blocks.
- `\cbstart{}`/`\cbend{}` must not be used inside a `tikzpicture`.
- Single-line inline `\cbstart{}`/`\cbend{}` produces a zero-height bar — use `{.added}` instead.
- The change colour `ufochanged` is IBM Magenta-50 (`#EE538B`) — CVD-safe. Do not substitute red.
- `::: added` applies a light magenta background tint to the block — matches inline `{.added}`.
- `::: deleted` strikes through every bullet and greys the text — matches inline `{.deleted}`.

---

## Slide authoring

### Content slide

```markdown
# Slide Title

- Bullet one
- Bullet two
```

### Section divider

```markdown
# Section Name {.unnumbered}

```{=latex}
\sectionslide{Section Name}
```
```

- `{.unnumbered}` suppresses a TOC entry
- Do **not** use `{.plain}` — it hides the page number

### Speaker notes (hidden on slides)

```markdown
::: notes
Notes visible only in notes/speakernotes PDFs.
:::
```

### Instruction blocks (speakernotes PDF only)

```markdown
::: instruction
Guidance for the presenter — rendered in an amber box in the speakernotes PDF only.
:::
```

---

## Colour palette

All named colours are defined in `themes/ufo-beamer/beamertheme.tex` and are
available everywhere in slide content. Use these — do not invent ad-hoc RGB
values for structural elements.

### Theme colours

| Name | Hex | Swatch | Role | Use in diagrams |
|---|---|---|---|---|
| `ufonavydark` | `#20203E` | ██ | Title text, section background | Node borders, arrow lines, body text labels |
| `ufoteal` | `#4C577D` | ██ | Frametitle, author, bullets | Secondary node borders, subdued arrows |
| `ufobullet` | `#4C577D` | ██ | Bullet colour (alias of teal) | Prefer `ufoteal` in TikZ |
| `ufolime` | `#C6E000` | ██ | Page number on dark/section slides | Accent on dark backgrounds only |
| `ufopagenumber` | `#BAC0D4` | ██ | Page number on content slides | Subdued labels, annotations |
| `ufochanged` | `#EE538B` | ██ | **Change highlights** — IBM Magenta-50, CVD-safe | Changebars, highlight rings, new arrows; **never substitute red** |
| `ufolink` | `#0066CC` | ██ | Hyperlinks | Clickable URL text only |
| `codebg` | `#F5F5F5` | ██ | Code block background | — |

### CVD-safe categorical palette

Use these five colours whenever colour alone distinguishes data series, diagram
node categories, or legend entries. They are perceivable as distinct by people
with **protanopia**, **deuteranopia**, and **tritanopia** (the three most common
forms of colour vision deficiency), and they remain separable in greyscale print
because they differ in both hue **and** luminance.

This palette follows the IBM adaptation of the [Wong (2011)](https://www.nature.com/articles/nmeth.1618)
CVD-safe set. Source: <https://www.color-hex.com/color-palette/1044488>.

| Name | Hex | Swatch | Luminance | Suggested role |
|---|---|---|---|---|
| `cvdgold` | `#ffb000` | ██ | High | Warning / caution category |
| `cvdorange` | `#fe6100` | ██ | Mid-high | Second data series |
| `cvdmagenta` | `#dc267f` | ██ | Mid | Error / removal / third series |
| `cvdviolet` | `#785ef0` | ██ | Mid-low | Feature / new capability category |
| `cvdblue` | `#648fff` | ██ | Mid | Info / primary series |

**Do not** use arbitrary brand colours for multi-series data — IBM brand colours
are not guaranteed to be CVD-safe in combination. Reserve `ufochanged` (#EE538B)
exclusively for change markup; use `cvdmagenta` (#dc267f) for data series.

TikZ usage: `fill=cvdblue!20, draw=cvdblue` for a light-fill node in the blue slot.

### Tint variants

TikZ tint syntax (`colour!N`) works on all named colours:

| Tint | Typical use |
|---|---|
| `ufonavydark!30` | Light navy border on diagram boxes |
| `ufonavydark!20` | Very light navy ruled lines inside boxes |
| `ufonavydark!6` | Near-white fill for decision nodes |
| `ufochanged!15` | Very light magenta fill (`\ufoAdded{}` highlight) |
| `ufochanged!35` | Semi-transparent magenta for halo glow postaction |
| `cvdblue!20` | Light blue fill for "feature" nodes |
| `cvdviolet!15` | Light violet fill for "new capability" nodes |

### Diagram conventions

- **Existing nodes**: `ufonavydark` border, white fill (action/terminal) or `ufonavydark!6` fill (decision)
- **Existing arrows**: `ufonavydark` or `ufoteal` colour
- **New/changed nodes**: normal style + dashed `ufochanged` highlight ring drawn outside
- **New/changed arrows**: `ufochanged` with `newarrow` halo-glow style
- **All-new diagram**: normal colours + explicit `ufochanged` margin bar at far-left
- **Multi-series diagrams**: use `cvdgold`, `cvdorange`, `cvdmagenta`, `cvdviolet`, `cvdblue` for up to five distinct categories

---

## Commit conventions

Use conventional commit prefixes and attribute AI assistance when applicable.

### Prefixes

| Prefix | Use for |
|:-------|:--------|
| `feat:` | New UFO or new theme capability |
| `fix:` | Correction to an existing UFO or theme bug |
| `theme:` | Changes to `themes/ufo-beamer/` (filters, theme, build rules, examples) |
| `docs:` | README, AGENTS.md, or other documentation only |
| `chore:` | Housekeeping (renames, gitignore, CI) |

### AI attribution

When a commit includes AI-generated or AI-assisted content, add a trailer
identifying the tool and version:

```
Co-authored-by-AI: <Tool Name> <version>
```

Examples:

```
Co-authored-by-AI: IBM Bob 2.0.5
Co-authored-by-AI: GitHub Copilot 1.256
Co-authored-by-AI: Claude 3.7 Sonnet
Co-authored-by-AI: ChatGPT 4o
```

Use the product name and version as shown in the tool's own UI or
documentation. Place the trailer as the last line of the commit message
body, after a blank line:

```
theme: add table-filter.lua; reorganise examples; update AGENTS.md

Converts Pandoc pipe tables to \tabular for Beamer compatibility.
...

Co-authored-by-AI: IBM Bob 2.0.5
```

---

## What not to do

- Do not edit files in `themes/ufo-beamer/` for a single UFO's needs
- Do not commit anything under `output/`
- Do not use `{.plain}` on section slides
- Do not put `<` or `>` in the `title` front matter field
- Do not hardcode `../theme/` or `../themes/ufo-beamer/` paths — use the `git rev-parse` pattern
- Do not use red for change indicators — always use `ufochanged` (IBM Magenta-50)
