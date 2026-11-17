# Root Makefile for UFO repository
# Builds the container image or invokes UFO builds

CONTAINER_ENGINE ?= $(shell which podman 2>/dev/null || which docker 2>/dev/null)
IMAGE_NAME       ?= ufo-builder

.PHONY: all image clean slides

all:
	@for ufo in ufos/*/; do \
	  if [ -f "$$ufo/Makefile" ]; then \
	    echo "==> Building $$ufo"; \
	    $(MAKE) -C "$$ufo" all || exit 1; \
	  fi; \
	done

slides:
	@for ufo in ufos/*/; do \
	  if [ -f "$$ufo/Makefile" ]; then \
	    echo "==> Building $$ufo (slides)"; \
	    $(MAKE) -C "$$ufo" slides || exit 1; \
	  fi; \
	done

image:
	$(CONTAINER_ENGINE) build -t $(IMAGE_NAME) .

clean:
	@for ufo in ufos/*/; do \
	  if [ -f "$$ufo/Makefile" ]; then \
	    $(MAKE) -C "$$ufo" clean; \
	  fi; \
	done
