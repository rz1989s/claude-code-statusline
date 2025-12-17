# Claude Code Statusline - Alpine Image
# Lightweight image for testing and development
#
# Build: docker build -t claude-statusline .
# Run:   docker run --rm claude-statusline
# Test:  docker run --rm claude-statusline bats tests/unit/*.bats

FROM alpine:3.19

LABEL maintainer="rz1989s"
LABEL description="Claude Code Enhanced Statusline - Alpine"
LABEL org.opencontainers.image.source="https://github.com/rz1989s/claude-code-statusline"

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    jq \
    curl \
    git \
    coreutils \
    grep \
    sed \
    gawk

# Install dev/test dependencies
RUN apk add --no-cache \
    bats \
    npm \
    shellcheck

# Set bash as default shell
SHELL ["/bin/bash", "-c"]

WORKDIR /app

# Copy source files
COPY . .

# Make scripts executable
RUN chmod +x statusline.sh install.sh

# Install npm dependencies for tests
RUN npm ci --ignore-scripts 2>/dev/null || true

# Verify installation
RUN bash --version && jq --version && bats --version

# Default entrypoint runs statusline
ENTRYPOINT ["./statusline.sh"]

# Default command (can be overridden)
CMD []
