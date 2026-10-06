# UFO — Upcoming Feature Overview

This repo contains the UFO toolchain and submitted UFOs for Open Liberty features.

```
themes/ufo-beamer/   ← Beamer theme, build scripts, Lua filters
templates/ufo/       ← blank UFO to copy for a new feature
<feature>/           ← submitted UFOs (e.g. 33070-conditional-ws-at)
output/              ← built PDFs land here (gitignored)
```

---

## Prerequisites

Install these once on your machine:

| Tool | Version | How to get it |
|---|---|---|
| **pandoc** | ≥ 3.x | `brew install pandoc` · [pandoc.org](https://pandoc.org/installing.html) |
| **XeLaTeX** | any recent | `brew install --cask mactex-no-gui` (macOS) · `apt install texlive-xetex` (Linux) |
| **Trebuchet MS** + **Arial** | — | Ships with macOS · Linux: `apt install ttf-mscorefonts-installer` |
| **Python 3** | ≥ 3.8 | `brew install python` · ships with most systems |
| **Node.js** | ≥ 18 | `brew install node` · [nodejs.org](https://nodejs.org/) |
| **@mermaid-js/mermaid-cli** | ≥ 12 | `npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli` |

### Verify your environment

Run this from the repo root to check everything is in place:

```bash
pandoc --version          # need ≥ 3.0
xelatex --version         # need any recent TeXLive
mmdc --version            # need ≥ 12.0.0
python3 --version         # need ≥ 3.8
node --version            # need ≥ 18
```

### Mermaid note

`@mermaid-js/mermaid-cli` uses [Puppeteer](https://pptr.dev/) to render diagrams headlessly.
The `--allow-scripts=puppeteer` flag permits Puppeteer's post-install script to download
its bundled Chromium. This is a one-time download (~170 MB) and is required for diagram
rendering. On Linux you may also need:

```bash
# Debian/Ubuntu — Chromium system dependencies
sudo apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libxkbcommon0 libxcomposite1 libxdamage1 \
  libxfixes3 libxrandr2 libgbm1 libasound2
```

---

## Using Podman

`podman` is a drop-in replacement for `docker` in this repo — the same flags,
volume syntax, and image name all work unchanged.

The base image (`registry.redhat.io/ubi9/ubi-minimal`) requires Red Hat
registry authentication.  Log in once before building:

```bash
podman login registry.redhat.io
```

Then substitute `podman` for `docker` in any command:

```bash
# Build the image
podman build -t ufo-builder .

# Build slides from inside a UFO directory
podman run --rm -v "$PWD":/workspace ufo-builder make slides

# All four variants
podman run --rm -v "$PWD":/workspace ufo-builder make all
```

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
cp -r templates/ufo 33070-conditional-ws-at
cd 33070-conditional-ws-at
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
git add 33070-conditional-ws-at
git commit -m "feat: add UFO for conditional WSAT (OL-33070)"
git push origin main
```

Open a pull request from your fork back to `OpenLiberty/ufo`.

### Commit conventions

| Prefix | Use for |
|:-------|:--------|
| `feat:` | New UFO or new theme capability |
| `fix:` | Correction to an existing UFO or theme bug |
| `theme:` | Changes to `themes/ufo-beamer/` (filters, theme, build rules, examples) |
| `docs:` | README, AGENTS.md, or other documentation only |
| `chore:` | Housekeeping (renames, gitignore, CI) |

**AI attribution** — when a commit includes AI-assisted content, add a trailer
with the tool name and version as shown in the tool's own UI:

```
Co-authored-by-AI: <Tool Name> <version>
```

For example: `Co-authored-by-AI: IBM Bob 2.0.5`, `Co-authored-by-AI: GitHub Copilot 1.256`,
`Co-authored-by-AI: Claude 3.7 Sonnet`, `Co-authored-by-AI: ChatGPT 4o`.

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
[`themes/ufo-beamer/examples/changebars/`](themes/ufo-beamer/examples/changebars/)
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
│       ├── table-filter.lua     ← Pandoc filter: pipe tables → \tabular
│       ├── epics.sh             ← epic validation + slug/link generation
│       ├── epic-prefixes.conf   ← recognised epic prefixes
│       ├── check-overflow.py    ← post-build slide overflow checker
│       ├── generate-handouts.py ← notes/handout/speakernotes PDF generator
│       ├── *.png                ← background images
│       └── examples/
│           ├── changebars/      ← worked example of all changebar patterns
│           ├── mermaid-diagrams/ ← Mermaid diagram type examples
│           └── tables/          ← pipe table patterns
├── templates/
│   └── ufo/                     ← copy this to start a new UFO
│       ├── Makefile
│       ├── images/              ← feature-specific images go here
│       └── slides/
│           ├── 00-title.md
│           ├── 01-design-thinking.md
│           ├── 02-externals-design.md
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
          $(SLIDES_DIR)/02-externals-design.md \
          $(SLIDES_DIR)/03-quality.md

# WITH_CHANGES = true   ← uncomment for a revised UFO

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

---

## Colour palette

All named colours are available in `beamertheme.tex`. Use them in TikZ diagrams
and slide content — do not invent ad-hoc RGB values.

### Theme colours

| Name | Hex | Role |
|---|---|---|
| `ufonavydark` | `#20203E` ![#20203E](https://via.placeholder.com/12/20203E/20203E.png) | Title text, section background, node borders |
| `ufoteal` | `#4C577D` ![#4C577D](https://via.placeholder.com/12/4C577D/4C577D.png) | Frametitle, bullets, secondary borders |
| `ufolime` | `#C6E000` ![#C6E000](https://via.placeholder.com/12/C6E000/C6E000.png) | Page number on dark slides |
| `ufopagenumber` | `#BAC0D4` ![#BAC0D4](https://via.placeholder.com/12/BAC0D4/BAC0D4.png) | Page number on content slides |
| `ufochanged` | `#EE538B` ![#EE538B](https://via.placeholder.com/12/EE538B/EE538B.png) | Change markup — IBM Magenta-50, CVD-safe |
| `ufolink` | `#0066CC` ![#0066CC](https://via.placeholder.com/12/0066CC/0066CC.png) | Hyperlinks |

### CVD-safe categorical palette

Use these for data series, diagram node categories, and any context where
colour alone conveys meaning. They are distinguishable by people with all
common forms of colour vision deficiency (protanopia, deuteranopia,
tritanopia) and remain separable in greyscale because they differ in both
**hue and luminance**. Source: [IBM / Wong 2011](https://www.color-hex.com/color-palette/1044488).

| Name | Hex | Swatch | Luminance | Role |
|---|---|---|---|---|
| `cvdgold` | `#ffb000` | ![#ffb000](https://via.placeholder.com/12/ffb000/ffb000.png) | High | Warning / caution |
| `cvdorange` | `#fe6100` | ![#fe6100](https://via.placeholder.com/12/fe6100/fe6100.png) | Mid-high | Second series |
| `cvdmagenta` | `#dc267f` | ![#dc267f](https://via.placeholder.com/12/dc267f/dc267f.png) | Mid | Error / removal |
| `cvdviolet` | `#785ef0` | ![#785ef0](https://via.placeholder.com/12/785ef0/785ef0.png) | Mid-low | Feature / new |
| `cvdblue` | `#648fff` | ![#648fff](https://via.placeholder.com/12/648fff/648fff.png) | Mid | Info / primary |

> **Do not** use `ufochanged` for data series — it is reserved exclusively for
> change markup. Use `cvdmagenta` instead when you need a magenta data category.
