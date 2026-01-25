# Docker image for testing zmux installation and functionality
FROM debian:bookworm-slim

# Install basic dependencies (git is assumed pre-installed in description, but we ensure it)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    bash \
    zsh \
    tmux \
    ncurses-bin \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a test user (non-root testing)
RUN useradd -m -s /bin/bash testuser

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Install fzf manually (avoiding interactive prompts)
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
    && ~/.fzf/install --bin

# Copy zmux project into container
COPY --chown=testuser:testuser . /home/testuser/zmux

# Set working directory to zmux
WORKDIR /home/testuser/zmux

# Run tests by default
CMD ["bash", "tests/run-tests.sh"]
