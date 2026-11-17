FROM docker.io/library/ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies: TeX Live (XeLaTeX), fonts, Python, Node.js, and Chromium libraries for Puppeteer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    fontconfig \
    fonts-ibm-plex \
    git \
    lmodern \
    make \
    nodejs \
    npm \
    python3 \
    texlive-xetex \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-pictures \
    texlive-plain-generic \
    texlive-lang-english \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2t64 \
    && fc-cache -f -v \
    && rm -rf /var/lib/apt/lists/*

# Install latest Pandoc (>= 3.2 required for --syntax-highlighting flag)
RUN ARCH=$(dpkg --print-architecture) && \
    PANDOC_DEB_URL=$(curl -fsSL https://api.github.com/repos/jgm/pandoc/releases/latest | grep "browser_download_url.*-${ARCH}\.deb" | cut -d '"' -f 4) && \
    curl -fsSL -o /tmp/pandoc.deb "${PANDOC_DEB_URL}" && \
    dpkg -i /tmp/pandoc.deb && \
    rm -f /tmp/pandoc.deb

# Install @mermaid-js/mermaid-cli for rendering Mermaid diagrams in slides
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false
RUN npm install -g --allow-scripts=puppeteer @mermaid-js/mermaid-cli \
    && rm -rf /root/.npm

# Configure Puppeteer to run in container environments with --no-sandbox
ENV PUPPETEER_CONFIG=/etc/puppeteer-config.json
RUN echo '{"args": ["--no-sandbox", "--disable-setuid-sandbox"]}' > /etc/puppeteer-config.json

# Signal to makefiles that builds inside the container are local
ENV FORCE_LOCAL=true

# Create non-root user and workspace directory
RUN useradd -m -u 1001 -s /bin/bash appuser && \
    mkdir -p /workspace && \
    chown -R appuser:appuser /workspace

WORKDIR /workspace

USER 1001

CMD ["make", "all"]
