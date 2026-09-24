# UFO — Upcoming Feature Overview

This repo contains the UFO toolchain and submitted UFOs for Open Liberty features.

```
themes/ufo-beamer/   ← Beamer theme, build scripts, Lua filters
templates/ufo/       ← blank UFO to copy for a new feature
<feature>/           ← submitted UFOs (e.g. 33070-conditional-wsat)
output/              ← built PDFs land here (gitignored)
```

---

## Prerequisites

Install these once on your machine:

| Tool | How to get it |
|---|---|
| **pandoc** ≥ 3.x | `brew install pandoc` · [pandoc.org](https://pandoc.org/installing.html) |
| **XeLaTeX** | `brew install --cask mactex-no-gui` (macOS) · `apt install texlive-xetex` (Linux) |
| **Trebuchet MS** + **Arial** | Ships with macOS · Linux: `apt install ttf-mscorefonts-installer` |
| **Python 3** | `brew install python` · ships with most systems |

---

## Creating a new UFO

### 1. Get the repo

Fork [`OpenLiberty/ufo`](https://github.com/OpenLiberty/ufo) and clone your fork:

```bash
git clone git@github.com:<your-id>/ufo.git
cd ufo
```

### 2. Create your UFO directory

Copy the template into a top-level directory named `<issue>-<feature-slug>`:

```bash
cp -r templates/ufo 33070-conditional-wsat
cd 33070-conditional-wsat
```

### 3. Fill in the front matter

Edit `slides/00-title.md`:

```yaml
---
title: "Conditional WSAT"
architect: "Jane Smith"
ufo-date: "2025-Q3"
epics: "OL-33070"
date: ""
---
```

| Field | Purpose |
|---|---|
| `title` | Title slide + output filename (downcased, hyphenated) |
| `architect` | Author block: "Architect: …" |
| `ufo-date` | Author block: "Date: …" (`date` left blank suppresses pandoc's auto-date) |
| `epics` | Comma-separated epic IDs rendered as hyperlinks; included in filename |

**Epic format** — each ID must match one of:

| Prefix | Tracker |
|---|---|
| `OL-nnnnn` | [OpenLiberty/open-liberty](https://github.com/OpenLiberty/open-liberty/issues) |
| `CL-nnnnn` | [websphere/WS-CD-Open](https://github.ibm.com/websphere/WS-CD-Open/issues) |
| `MORE-nnnnn` | [websphere/project-london](https://github.ibm.com/websphere/project-london/issues) |

The build fails with a clear error for any unrecognised prefix. To add prefixes edit
[`themes/ufo-beamer/epic-prefixes.conf`](themes/ufo-beamer/epic-prefixes.conf).

> Do **not** use `<` or `>` in the title — Pandoc treats them as HTML tags.

### 4. Complete the slides

Work through `slides/01-design-thinking.md` → `slides/03-quality.md`.
Each file contains `::: instruction` blocks explaining what to include — visible
only in the `speakernotes` PDF.

### 5. Build

Run from inside your UFO directory:

```bash
make          # → output/ufo-ol-33070-conditional-ws-at-slides.pdf
make all      # → all four formats (slides, notes, handout, speakernotes)
```

All PDFs land in the repo-level `output/` directory (gitignored).

### 6. Open a PR

```bash
git add 33070-conditional-wsat
git commit -m "feat: add UFO for conditional WSAT (OL-33070)"
git push origin main
```

Open a pull request from your fork back to `OpenLiberty/ufo`.

---

## Build targets

| Target | Output |
|---|---|
| `make` / `make slides` | Presentation slides PDF |
| `make all` | All four artefacts |
| `make notes` | Speaker notes — one slide + notes per page, no slide image |
| `make handout` | Handout — slide image + notes per page |
| `make speakernotes` | Speaker notes + instruction boxes per page |
| `make clean` | Remove `build/` and this UFO's PDFs from `output/` |

---

## Marking up changes (revision highlighting)

When submitting a **revised** UFO, highlight what changed so reviewers can scan quickly.
Three markup types are available; see the worked example at
[`themes/ufo-beamer/examples/changebar-demo/`](themes/ufo-beamer/examples/changebar-demo/)
for a rendered PDF showing each pattern.

### Changed bullets or paragraphs

Wrap any modified block in a fenced div — a magenta bar appears in the left margin:

```markdown
::: changed
- This bullet was added or reworded
:::
```

### Added inline text

Surround new wording with `[…]{.added}` — renders with a light magenta highlight:

```markdown
The `propagation` attribute now accepts [`conditional`]{.added} and `never`.
```

### Deleted inline text

Surround removed wording with `[…]{.deleted}` — renders with strikethrough:

```markdown
Calls to [`all`]{.deleted} [`opted-in`]{.added} endpoints are affected.
```

### New TikZ diagrams

Draw a vertical changebar explicitly in the far-left margin (outside all content):

```latex
\draw[ufochanged, line width=2.5pt, line cap=round]
  (-5.0, 0.35) -- (-5.0, -2.55);
```

### New nodes in an existing TikZ diagram

Add a `fit` node drawn as a dashed magenta ring around the new node:

```latex
\node[draw=ufochanged, line width=1.8pt, dashed,
      dash pattern=on 4pt off 2pt,
      rounded corners=5pt, fill=none,
      fit=(newnode), inner sep=4pt] {};
```

### New paths in an existing TikZ diagram

Use the `newarrow` style (magenta arrow with semi-transparent halo glow):

```latex
newarrow/.style={draw=ufochanged, -latex, thick,
                 postaction={draw=ufochanged, line width=5pt, opacity=0.18}}
```

### Activating the change key on the title slide

Add `EXTRA_VARS_TEX = \ufochangestrue` to your `Makefile` before the `include` line.
This draws a "Changes detected!" key in the open beam area of the title slide.

---

## Slide authoring reference

### Content slides

```markdown
# Slide Title

- Bullet one
- Bullet two
```

### Section divider slides

```markdown
# Section Name {.unnumbered}

```{=latex}
\sectionslide{Section Name}
```
```

The `{.unnumbered}` suppresses a TOC entry. `\sectionslide{}` draws the full-bleed
dark background. Do **not** use `{.plain}` — it hides the page number.

### Speaker notes

```markdown
::: notes
Notes text here — hidden on slides, shown in notes/speakernotes PDFs.
:::
```

### Instruction blocks

```markdown
::: instruction
Guidance for the presenter — hidden on slides and handout, shown in speakernotes PDF.
:::
```

---

## File structure

```
ufo/
├── README.md
├── themes/
│   └── ufo-beamer/              ← shared theme — do not edit per-UFO
│       ├── ufo-beamer.mk        ← included by every UFO Makefile
│       ├── beamertheme.tex      ← Beamer theme (colours, layout, changebar commands)
│       ├── changebar-filter.lua ← Pandoc filter: ::: changed, {.added}, {.deleted}
│       ├── instruction-filter.lua
│       ├── epics.sh             ← epic validation + slug/link generation
│       ├── epic-prefixes.conf   ← recognised epic prefixes
│       ├── check-overflow.py    ← post-build slide overflow checker
│       ├── generate-handouts.py ← notes/handout/speakernotes PDF generator
│       ├── *.png                ← background images
│       └── examples/
│           └── changebar-demo/  ← worked example of all changebar patterns
├── templates/
│   └── ufo/                     ← copy this to start a new UFO
│       ├── Makefile
│       ├── images/              ← feature-specific images go here
│       └── slides/
│           ├── 00-title.md
│           ├── 01-design-thinking.md
│           ├── 02-feature-design.md
│           └── 03-quality.md
├── output/                      ← built PDFs (gitignored)
└── <feature>/                   ← submitted UFOs (same structure as templates/ufo/)
    ├── Makefile
    ├── images/
    └── slides/
```

### UFO Makefile

Each UFO Makefile is just a few lines — set `SOURCES`, optionally `EXTRA_VARS_TEX`
and `PDF_PREFIX`, then include the shared rules:

```makefile
SOURCES = $(SLIDES_DIR)/00-title.md \
          $(SLIDES_DIR)/01-design-thinking.md \
          $(SLIDES_DIR)/02-feature-design.md \
          $(SLIDES_DIR)/03-quality.md

# EXTRA_VARS_TEX = \ufochangestrue   ← uncomment for a revised UFO

include $(shell git rev-parse --show-toplevel)/themes/ufo-beamer/ufo-beamer.mk
```

---

## Design reference

| Element | Value |
|---|---|
| Page size | 254 mm × 142.875 mm |
| Frametitle font | Trebuchet MS 40 pt, `#4C577D` |
| Body font | Arial 24 pt, 110 % leading |
| Title font | Trebuchet MS 24 pt bold, `#20203E` |
| Section title | Trebuchet MS 54 pt white, centred |
| Page number | 15 pt, `#BAC0D4` (content) · `#C6E000` lime (section) · suppressed (title) |
| Change highlight | IBM Magenta-50 `#EE538B` — CVD-safe |
