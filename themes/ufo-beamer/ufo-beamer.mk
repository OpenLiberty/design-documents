# ufo-beamer.mk — shared rules for all UFO Makefiles
#
# Each UFO Makefile must set these variables BEFORE including this file:
#
#   SOURCES        — space-separated list of slide .md files (must include
#                    $(SLIDES_DIR)/00-title.md first)
#   EXTRA_VARS_TEX — (optional) extra \LaTeX lines injected into the preamble,
#                    e.g. '\ufochangestrue' to activate the change key on the
#                    title slide. Leave unset or empty if not needed.
#
# Standard variables with defaults that can be overridden before the include:
#
#   BUILD_DIR  (default: build)       — intermediate LaTeX artefacts, gitignored locally
#   SLIDES_DIR (default: slides)
#   IMAGES_DIR (default: images)
#   OUTPUT_DIR (default: <git-root>/output) — final PDFs, gitignored at repo root

BUILD_DIR  ?= build
SLIDES_DIR ?= slides
IMAGES_DIR ?= images

# Locate the theme and shared output dir via the git root — works wherever
# the UFO folder is placed inside the repository.
GIT_ROOT   := $(shell git rev-parse --show-toplevel)
THEME_DIR   = $(GIT_ROOT)/themes/ufo-beamer
OUTPUT_DIR ?= $(GIT_ROOT)/output

TITLE_MD = $(SLIDES_DIR)/00-title.md

THEME     = $(THEME_DIR)/beamertheme.tex
THEME_ALL = $(wildcard $(THEME_DIR)/*)

EPICS_SH       = $(THEME_DIR)/epics.sh
CHECK_OVERFLOW = python3 $(THEME_DIR)/check-overflow.py

# Extract fields from the title slide front matter
TITLE_SLUG := $(shell grep '^title:'     $(TITLE_MD) | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//;s/"$$//' \
                | tr '[:upper:]' '[:lower:]' \
                | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$$//')
ARCHITECT  := $(shell grep '^architect:' $(TITLE_MD) | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//;s/"$$//')
EPICS      := $(shell grep '^epics:'     $(TITLE_MD) | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//;s/"$$//')

# Error if ufo-date is still present — date is now auto-generated from git.
ifneq ($(shell grep '^ufo-date:' $(TITLE_MD)),)
  $(error $(TITLE_MD) contains a 'ufo-date:' field. Remove it — the date is now auto-generated from git.)
endif

# Git-derived date, sha, and draft state.
# If any source file has uncommitted changes: draft mode, today's date, ???????? sha.
# Otherwise: date and sha from the last commit touching the sources.
_GIT_DIRTY := $(shell git status --porcelain $(SOURCES) 2>/dev/null)
ifneq ($(_GIT_DIRTY),)
  GIT_DATE  := $(shell date '+%Y-%m-%d')
  GIT_SHA   := ????????????
  GIT_DRAFT := true
else
  GIT_DATE  := $(shell git log -1 --format=%cd --date=format:'%Y-%m-%d' -- $(SOURCES) 2>/dev/null)
  GIT_SHA   := $(shell git log -1 --abbrev=12 --format=%h -- $(SOURCES) 2>/dev/null)
  GIT_DRAFT := false
endif

# Validate epics, then derive slug and LaTeX links via epics.sh
_EPIC_VALIDATE := $(shell $(EPICS_SH) validate "$(EPICS)" 2>&1 || true)
ifneq ($(_EPIC_VALIDATE),)
  $(error $(_EPIC_VALIDATE))
endif
EPICS_SLUG  := $(shell $(EPICS_SH) slug  "$(EPICS)")
EPICS_LINKS := $(shell $(EPICS_SH) links "$(EPICS)")

# PDF filename prefix — override to 'example-' (or anything else) in the
# UFO Makefile before the include if this is not a real UFO.
PDF_PREFIX ?= ufo-

PDF_STEM         = $(PDF_PREFIX)$(EPICS_SLUG)-$(TITLE_SLUG)
PDF_SLIDES       = $(OUTPUT_DIR)/$(PDF_STEM)-slides.pdf
PDF_NOTES        = $(OUTPUT_DIR)/$(PDF_STEM)-notes.pdf
PDF_HANDOUT      = $(OUTPUT_DIR)/$(PDF_STEM)-handout.pdf
PDF_SPEAKERNOTES = $(OUTPUT_DIR)/$(PDF_STEM)-speakernotes.pdf

VARS_TEX = $(BUILD_DIR)/ufo-vars.tex

# VARS_TEX must be regenerated on every build so the git dirty check is fresh.
.PHONY: slides all notes handout speakernotes clean $(VARS_TEX)

slides: $(PDF_SLIDES)

all: slides notes handout speakernotes

notes: $(PDF_NOTES)

handout: $(PDF_HANDOUT)

speakernotes: $(PDF_SPEAKERNOTES)

# Write preamble definitions into VARS_TEX.
# \graphicspath appends the theme dir so background images are found.
# EXTRA_VARS_TEX lets each UFO inject extra lines (e.g. \ufochangestrue).
# \author is set via \AtEndPreamble so hyperref is already loaded when
# \href is used inside the author block.
$(VARS_TEX): | $(BUILD_DIR)
	{ \
	  printf '\\graphicspath{{images/}{%s/}}\n' '$(THEME_DIR)'; \
	  printf '\\ufoGitSha{%s}\n' '$(GIT_SHA)'; \
	  printf '\\ufoGitDate{%s}\n' '$(GIT_DATE)'; \
	  $(if $(filter true,$(GIT_DRAFT)),printf '\\ufodrafttrue\n';) \
	  $(if $(EXTRA_VARS_TEX),printf '%s\n' '$(EXTRA_VARS_TEX)';) \
	  printf '\\AtEndPreamble{\n'; \
	  printf '  \\csname Hy@implicittrue\\endcsname\n'; \
	  printf '  \\hypersetup{colorlinks=true,urlcolor=ufolink}\n'; \
	  printf '  \\protected\\def\\insertauthor{\\parbox{0.55\\paperwidth}{\\raggedright Architect: %s \\\\[4pt]Date: %s \\\\[4pt]Commit: %s \\\\[4pt]Associated Epics: %s}}\n' \
	    '$(ARCHITECT)' '$(GIT_DATE)' '$(GIT_SHA)' '$(EPICS_LINKS)'; \
	  printf '}\n'; \
	} > $@

PANDOC_FLAGS = \
	-t beamer \
	--pdf-engine=xelatex \
	--syntax-highlighting=none \
	--lua-filter=$(THEME_DIR)/instruction-filter.lua \
	--lua-filter=$(THEME_DIR)/changebar-filter.lua \
	-H $(THEME) \
	-H $(VARS_TEX)

$(PDF_SLIDES): $(SOURCES) $(THEME_ALL) $(VARS_TEX) $(wildcard $(IMAGES_DIR)/*) | $(BUILD_DIR) $(OUTPUT_DIR)
	pandoc $(SOURCES) $(PANDOC_FLAGS) -o $(BUILD_DIR)/$(PDF_STEM)-slides.tex
	xelatex -interaction=nonstopmode -output-directory=$(BUILD_DIR) $(BUILD_DIR)/$(PDF_STEM)-slides.tex
	xelatex -interaction=nonstopmode -output-directory=$(BUILD_DIR) $(BUILD_DIR)/$(PDF_STEM)-slides.tex
	xelatex -interaction=nonstopmode -output-directory=$(BUILD_DIR) $(BUILD_DIR)/$(PDF_STEM)-slides.tex
	xelatex -interaction=nonstopmode -output-directory=$(BUILD_DIR) $(BUILD_DIR)/$(PDF_STEM)-slides.tex
	@$(CHECK_OVERFLOW) $(BUILD_DIR)/$(PDF_STEM)-slides.log $(BUILD_DIR)/$(PDF_STEM)-slides.tex || true
	mv $(BUILD_DIR)/$(PDF_STEM)-slides.pdf $(PDF_SLIDES)

$(PDF_NOTES): $(PDF_SLIDES) | $(OUTPUT_DIR)
	$(THEME_DIR)/generate-handouts.py $(PDF_SLIDES) notes $(PDF_NOTES)

$(PDF_HANDOUT): $(PDF_SLIDES) | $(OUTPUT_DIR)
	$(THEME_DIR)/generate-handouts.py $(PDF_SLIDES) handout $(PDF_HANDOUT)

$(PDF_SPEAKERNOTES): $(PDF_SLIDES) | $(OUTPUT_DIR)
	$(THEME_DIR)/generate-handouts.py $(PDF_SLIDES) speakernotes $(PDF_SPEAKERNOTES)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(PDF_SLIDES) $(PDF_NOTES) $(PDF_HANDOUT) $(PDF_SPEAKERNOTES)
