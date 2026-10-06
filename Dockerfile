# =====================================================================
# UFO Build Environment — Docker image
# =====================================================================
# Packages the complete toolchain for building UFO (Upcoming Feature
# Overview) slide decks with the ufo-beamer theme.
#
# Toolchain:
#   - Pandoc 3.x               (Lua filter support)
#   - TeX Live / xelatex        (beamer + all required packages)
#   - @mermaid-js/mermaid-cli   (mmdc v12+ — diagram rendering)
#   - Python 3                  (generate-handouts.py, check-overflow.py)
#   - git                       (git-derived date/sha in title slide)
#   - IBM Plex Sans             (IBM corporate typeface — body, titles; SIL OFL)
#   - IBM Plex Mono             (IBM corporate monospace — code blocks; SIL OFL)
#
# Usage:
#   # Build the image
#   docker build -t ufo-builder .
#   podman build -t ufo-builder .
#
#   # From inside any UFO directory (e.g. 33070-conditional-ws-at/)
#   docker run --rm -v "$PWD":/workspace ufo-builder make slides
#   podman run --rm -v "$PWD":/workspace ufo-builder make slides
#
#   # All four variants (slides + notes + handout + speakernotes)
#   docker run --rm -v "$PWD":/workspace ufo-builder make all
#
#   # Revised UFO with change highlighting
#   # (add WITH_CHANGES = true to the UFO Makefile first)
#   docker run --rm -v "$PWD":/workspace ufo-builder make slides
#
# Security:
#   - Base image: registry.redhat.io/ubi9/ubi-minimal (Red Hat trusted, minimal)
#   - Runs as non-root user (uid 1001)
#   - No secrets or credentials in image
#   - All fonts are SIL OFL-licensed; no proprietary MS fonts
#   - IBM Plex is IBM's official typeface (w3.ibm.com/support/article/ibm_plex)
# =====================================================================

FROM registry.redhat.io/ubi9/ubi-minimal:latest

USER root

# ---------------------------------------------------------------------
# 1. System packages
#
# UBI9 repos do NOT ship TeX Live or pandoc.  These are installed from
# upstream sources in subsequent steps.  Here we install everything
# else: tar/gzip/xz (for unpacking upstream archives), perl (for the
# TeX Live installer and tlmgr), python3, nodejs+npm, git, fontconfig,
# wget, and the Chromium runtime libraries needed by Puppeteer (mmdc).
# ---------------------------------------------------------------------

RUN microdnf install -y \
    \
    # — Archive tools (for unpacking upstream tarballs) —\
    tar \
    gzip \
    xz \
    \
    # — Perl + modules (required by TeX Live installer and tlmgr) —\
    perl \
    perl-URI \
    perl-Compress-Raw-Zlib \
    perl-IO-Compress \
    perl-Digest-MD5 \
    perl-PathTools \
    perl-File-Temp \
    perl-Getopt-Long \
    perl-Pod-Simple \
    perl-Module-Metadata \
    perl-LWP-Protocol-https \
    perl-Net-SSLeay \
    perl-libwww-perl \
    \
    # — Python 3 (for generate-handouts.py, check-overflow.py) —\
    python3 \
    \
    # — Node.js (system version is v16; replaced by official v18+ binary in step 5) —\
    nodejs \
    npm \
    \
    # — git (for git-derived date/sha injected into UFO title slide) —\
    git \
    \
    # — Font configuration + network utilities —\
    fontconfig \
    ca-certificates \
    wget \
    \
    # — Puppeteer / Chromium runtime libraries (required by mmdc) —\
    nss \
    atk \
    at-spi2-atk \
    cups-libs \
    libxkbcommon \
    libXScrnSaver \
    libXcomposite \
    libXcursor \
    libXdamage \
    libXfixes \
    libXi \
    libXrandr \
    mesa-libgbm \
    alsa-lib \
    \
    && microdnf clean all

# ---------------------------------------------------------------------
# 2. TeX Live (from upstream — not shipped in UBI9 repos)
#
# Installs scheme-small (minimal but sufficient) then adds the specific
# collections that the UFO theme and handout generator need:
#
#   scheme-small          → beamer, xcolor, graphicx, hyperref, amssymb, ...
#   collection-xetex      → xelatex engine + fontspec
#   collection-latexextra → tcolorbox, enumitem, zref, ulem, xurl
#   collection-pictures   → tikz, eso-pic, pgf
#   collection-fontsextra → additional font support
#
# Documentation and source files are skipped to reduce image size.
# ---------------------------------------------------------------------

RUN mkdir -p /tmp/tl-installer && \
    cd /tmp/tl-installer && \
    wget -q https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    tar xzf install-tl-unx.tar.gz && \
    printf "selected_scheme scheme-small\noption_doc 0\noption_src 0\n" > /tmp/texlive.profile && \
    ./install-tl-*/install-tl -profile /tmp/texlive.profile && \
    TEXBIN=$(ls -d /usr/local/texlive/*/bin/*/) && \
    $TEXBIN/tlmgr option repository https://mirror.ctan.org/systems/texlive/tlnet && \
    $TEXBIN/tlmgr install \
      collection-xetex \
      collection-latexextra \
      collection-pictures \
      collection-fontsextra && \
    $TEXBIN/fmtutil-sys --all && \
    $TEXBIN/texhash && \
    rm -rf /tmp/tl-installer /tmp/texlive.profile

# Symlink TeX Live binaries (xelatex, tlmgr, texhash, ...) into /usr/local/bin
RUN TEXBIN=$(ls -d /usr/local/texlive/*/bin/*/) && \
    ln -sf ${TEXBIN}* /usr/local/bin/

# Individual packages not covered by the collections above.
# newunicodechar: used in beamertheme.tex to remap ⭐ to \star.
RUN tlmgr install newunicodechar

# ---------------------------------------------------------------------
# 3. IBM Plex typeface (IBM's official corporate typeface, SIL OFL)
#
# IBM Plex Sans  — body text, titles, author lines
# IBM Plex Mono  — code blocks (fancyvrb verbatim environments)
#
# Installed from the official IBM/plex GitHub releases.
# OTF files go into /usr/share/fonts/ibm-plex and are registered with
# fontconfig so XeLaTeX's fontspec can resolve them by family name.
# ---------------------------------------------------------------------

RUN PLEX_SANS_URL=$(curl -sL "https://api.github.com/repos/IBM/plex/releases?per_page=100" | \
      python3 -c "import sys,json; r=json.load(sys.stdin); print(next((a['browser_download_url'] for rel in r for a in rel.get('assets',[]) if 'plex-sans@' in rel['tag_name'] and 'plex-sans-' not in rel['tag_name'] and a['name']=='ibm-plex-sans.zip' and 'variable' not in a['name']), ''))") && \
    PLEX_MONO_URL=$(curl -sL "https://api.github.com/repos/IBM/plex/releases?per_page=100" | \
      python3 -c "import sys,json; r=json.load(sys.stdin); print(next((a['browser_download_url'] for rel in r for a in rel.get('assets',[]) if 'plex-mono@' in rel['tag_name'] and 'variable' not in rel['tag_name'] and a['name']=='ibm-plex-mono.zip'), ''))") && \
    echo "IBM Plex Sans: $PLEX_SANS_URL" && \
    echo "IBM Plex Mono: $PLEX_MONO_URL" && \
    mkdir -p /tmp/plex /usr/share/fonts/ibm-plex && \
    curl -sL "$PLEX_SANS_URL" -o /tmp/plex/plex-sans.zip && \
    curl -sL "$PLEX_MONO_URL" -o /tmp/plex/plex-mono.zip && \
    unzip -q /tmp/plex/plex-sans.zip -d /tmp/plex/ && \
    unzip -q /tmp/plex/plex-mono.zip -d /tmp/plex/ && \
    find /tmp/plex -name "*.otf" -path "*/complete/otf/*" \
         -exec cp {} /usr/share/fonts/ibm-plex/ \; && \
    fc-cache -f && \
    fc-list | grep -i "ibm plex" | wc -l && \
    rm -rf /tmp/plex

# ---------------------------------------------------------------------
# 4. Pandoc (from official GitHub releases — not in UBI9 repos)
#    Uses the browser_download_url from the GitHub API to select the
#    correct asset for the current CPU architecture. The Python
#    expression is kept on one line to avoid shell quoting issues
#    in the Dockerfile RUN instruction.
# ---------------------------------------------------------------------

RUN PANDOC_URL=$(curl -sL "https://api.github.com/repos/jgm/pandoc/releases/latest" | \
     python3 -c "import sys,json,os; r=json.load(sys.stdin); arch='linux-arm64' if os.uname().machine=='aarch64' else 'linux-amd64'; print(next((a['browser_download_url'] for a in r.get('assets',[]) if arch in a['name']), ''))") && \
    echo "Downloading pandoc from: $PANDOC_URL" && \
    curl -sL "$PANDOC_URL" | tar xz -C /tmp && \
    PANDOC_DIR=$(ls -d /tmp/pandoc-*/ | head -1 | sed 's:/*$::') && \
    cp "${PANDOC_DIR}/bin/pandoc" /usr/local/bin/ && \
    if [ -d "${PANDOC_DIR}/share/pandoc" ]; then \
        cp -r "${PANDOC_DIR}/share/pandoc" /usr/local/share/; \
    fi && \
    rm -rf /tmp/pandoc-*

# ---------------------------------------------------------------------
# 5. Node.js (from official binary — UBI9 only ships v16, but mmdc v12
#    requires Node.js >= 18)
#    The official binary is installed to /usr/local/ and takes
#    precedence over the system node at /usr/bin/ via PATH ordering.
# ---------------------------------------------------------------------

RUN NODE_ARCH="linux-amd64" && \
    [ "$(uname -m)" = "aarch64" ] && NODE_ARCH="linux-arm64" && \
    NODE_VER=$(curl -sL https://nodejs.org/dist/latest/ | \
               grep -oP 'node-v\K[0-9]+\.[0-9]+\.[0-9]+' | head -1) && \
    echo "Installing Node.js v${NODE_VER} (${NODE_ARCH})" && \
    curl -sL "https://nodejs.org/dist/v${NODE_VER}/node-v${NODE_VER}-${NODE_ARCH}.tar.gz" | \
      tar xzf - -C /usr/local --strip-components=1 && \
    node --version && npm --version

# ---------------------------------------------------------------------
# 6. Mermaid CLI (mmdc v12+)
#    --allow-scripts=puppeteer lets Puppeteer download its bundled
#    headless Chromium during the npm install step.
#
#    PUPPETEER_CACHE_DIR is set to a world-readable location BEFORE the
#    install so the Chromium binary lands there rather than in /root/.cache.
#    The non-root builder user (uid 1001) must be able to find Chromium at
#    runtime, so the directory is made world-executable after install.
# ---------------------------------------------------------------------

RUN PUPPETEER_CACHE_DIR=/usr/local/share/puppeteer \
    npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli && \
    chmod -R a+rX /usr/local/share/puppeteer

# ---------------------------------------------------------------------
# 7. Non-root user (security best practice)
# ---------------------------------------------------------------------

RUN groupadd -g 1001 builder && \
    useradd -m -u 1001 -g 1001 -s /bin/bash builder

USER builder
WORKDIR /workspace

# PATH covers /usr/local/bin (pandoc, mmdc, TeX Live symlinks) and
# standard system paths.  TeX Live binaries are symlinked in step 3.
# PUPPETEER_CACHE_DIR must match the path used during npm install above so
# Puppeteer can locate chrome-headless-shell at runtime as the builder user.
ENV PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin \
    HOME=/home/builder \
    PUPPETEER_CACHE_DIR=/usr/local/share/puppeteer \
    # Mermaid diagram default render width (matches changebar-filter.lua default)
    MERMAID_FILTER_WIDTH=2400

CMD ["/bin/bash"]
