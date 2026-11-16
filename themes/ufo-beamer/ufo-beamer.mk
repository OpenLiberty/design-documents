# ufo-beamer.mk — shared entrypoint for UFO Makefiles
# Dispatches builds to container (podman / docker) on host, or compiles directly when inside container or FORCE_LOCAL=true.

GIT_ROOT   := $(shell git rev-parse --show-toplevel)
THEME_DIR   = $(GIT_ROOT)/themes/ufo-beamer

# Check if we are running inside the container or if local execution is forced
IS_CONTAINER := $(if $(filter 1,$(INSIDE_CONTAINER)),true,$(if $(wildcard /.dockerenv)$(wildcard /run/.containerenv),true,false))

ifeq ($(IS_CONTAINER),true)
  include $(THEME_DIR)/ufo-beamer-build.mk
else ifeq ($(FORCE_LOCAL),true)
  include $(THEME_DIR)/ufo-beamer-build.mk
else
  # Host dispatcher mode
  CONTAINER_ENGINE ?= $(shell which podman 2>/dev/null || which docker 2>/dev/null)
  ifeq ($(CONTAINER_ENGINE),)
    $(warning Neither podman nor docker found in PATH. Falling back to local tools.)
    include $(THEME_DIR)/ufo-beamer-build.mk
  else
    IMAGE_NAME ?= ufo-builder
    CURR_DIR   := $(shell pwd -P)
    REL_DIR    := $(patsubst $(GIT_ROOT)/%,%,$(CURR_DIR))
    TARGETS    := slides all notes handout speakernotes clean

    .PHONY: $(TARGETS) image

    # Default target
    .DEFAULT_GOAL := slides

    image:
	$(CONTAINER_ENGINE) build -t $(IMAGE_NAME) $(GIT_ROOT)

    $(TARGETS):
	@if ! $(CONTAINER_ENGINE) image exists $(IMAGE_NAME) 2>/dev/null && ! $(CONTAINER_ENGINE) image inspect $(IMAGE_NAME) >/dev/null 2>&1; then \
	  echo "Container image $(IMAGE_NAME) not found. Building it..."; \
	  $(CONTAINER_ENGINE) build -t $(IMAGE_NAME) $(GIT_ROOT); \
	fi
	$(CONTAINER_ENGINE) run --rm -v "$(GIT_ROOT):/workspace:z" -w "/workspace/$(REL_DIR)" $(IMAGE_NAME) make INSIDE_CONTAINER=1 $@
  endif
endif
