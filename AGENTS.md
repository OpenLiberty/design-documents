# UFO — Agent Instructions

This file provides agent-actionable conventions for working in this repository.
Read it before creating, editing, or building any UFO.

---

## Repository layout

```
ufo/
├── themes/ufo-beamer/       ← shared theme — never edit per-UFO
│   ├── ufo-beamer.mk        ← shared Makefile rules (included by every UFO)
│   ├── beamertheme.tex      ← Beamer theme, colours, changebar commands
│   ├── changebar-filter.lua ← Pandoc filter for change markup
│   ├── instruction-filter.lua
│   ├── epics.sh             ← epic validation + slug/link generation
│   ├── epic-prefixes.conf   ← recognised epic ID prefixes
│   ├── check-overflow.py    ← post-build overflow checker
│   ├── generate-handouts.py ← notes/handout/speakernotes generator
│   ├── *.png                ← background images
│   └── examples/changebar-demo/  ← worked changebar example (build to see output)
├── templates/ufo/           ← copy this to create a new UFO
├── output/                  ← all built PDFs land here (gitignored)
└── <issue>-<feature>/       ← one directory per submitted UFO
```

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

Every UFO Makefile must set `SOURCES` then include the shared rules. Optionally
set `EXTRA_VARS_TEX` (for a revised UFO) and `PDF_PREFIX` (for non-UFO outputs):

```makefile
SOURCES = $(SLIDES_DIR)/00-title.md \
          $(SLIDES_DIR)/01-design-thinking.md \
          $(SLIDES_DIR)/02-feature-design.md \
          $(SLIDES_DIR)/03-quality.md

# Uncomment for a revised UFO to activate the change key on the title slide:
# EXTRA_VARS_TEX = \ufochangestrue

include $(shell git rev-parse --show-toplevel)/themes/ufo-beamer/ufo-beamer.mk
```

The `include` path uses `git rev-parse --show-toplevel` so it resolves correctly
regardless of where the UFO directory sits in the repo.

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
See `themes/ufo-beamer/examples/changebar-demo/` for a rendered example
(run `make` there to build the PDF).

### Changed bullet or paragraph — magenta margin bar

```markdown
::: changed
- This bullet was modified or added
:::
```

### Added inline text — light magenta highlight

```markdown
The attribute now accepts [`conditional`]{.added} as a value.
```

### Deleted inline text — strikethrough

```markdown
Calls to [`all`]{.deleted} [`opted-in`]{.added} endpoints are affected.
```

### Whole new TikZ diagram — explicit margin bar

Draw a vertical rule just outside the leftmost content at a fixed x coordinate:

```latex
\draw[ufochanged, line width=2.5pt, line cap=round]
  (-5.0, 0.35) -- (-5.0, -2.55);
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

- `::: changed` works at block level (bullets, paragraphs). Do not use it to wrap raw `{=latex}` blocks.
- `\cbstart{}`/`\cbend{}` must not be used inside a `tikzpicture`.
- Single-line inline `\cbstart{}`/`\cbend{}` produces a zero-height bar — use `{.added}` instead.
- The change colour `ufochanged` is IBM Magenta-50 (`#EE538B`) — CVD-safe. Do not substitute red.

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

| Name | Hex | Role | Use in diagrams |
|---|---|---|---|
| `ufonavydark` | `#20203E` | Title text, section background | Node borders, arrow lines, body text labels |
| `ufoteal` | `#4C577D` | Frametitle, author, bullets | Secondary node borders, subdued arrows |
| `ufobullet` | `#4C577D` | Bullet colour (alias of teal) | Prefer `ufoteal` in TikZ |
| `ufolime` | `#C6E000` | Page number on dark/section slides | Accent on dark backgrounds only |
| `ufopagenumber` | `#BAC0D4` | Page number on content slides | Subdued labels, annotations |
| `ufochanged` | `#EE538B` | **Change highlights** — IBM Magenta-50, CVD-safe | Changebars, highlight rings, new arrows; **never substitute red** |
| `ufolink` | `#0066CC` | Hyperlinks | Clickable URL text only |
| `codebg` | `#F5F5F5` | Code block background | — |

### Tint variants

TikZ tint syntax (`colour!N`) works on all named colours:

| Tint | Typical use |
|---|---|
| `ufonavydark!30` | Light navy border on diagram boxes |
| `ufonavydark!20` | Very light navy ruled lines inside boxes |
| `ufonavydark!6` | Near-white fill for decision nodes |
| `ufochanged!15` | Very light magenta fill (`\ufoAdded{}` highlight) |
| `ufochanged!35` | Semi-transparent magenta for halo glow postaction |

### Diagram conventions

- **Existing nodes**: `ufonavydark` border, white fill (action/terminal) or `ufonavydark!6` fill (decision)
- **Existing arrows**: `ufonavydark` or `ufoteal` colour
- **New/changed nodes**: normal style + dashed `ufochanged` highlight ring drawn outside
- **New/changed arrows**: `ufochanged` with `newarrow` halo-glow style
- **All-new diagram**: normal colours + explicit `ufochanged` margin bar at far-left

---

## What not to do

- Do not edit files in `themes/ufo-beamer/` for a single UFO's needs
- Do not commit anything under `output/`
- Do not use `{.plain}` on section slides
- Do not put `<` or `>` in the `title` front matter field
- Do not hardcode `../theme/` or `../themes/ufo-beamer/` paths — use the `git rev-parse` pattern
- Do not use red for change indicators — always use `ufochanged` (IBM Magenta-50)
