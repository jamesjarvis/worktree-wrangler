FROM alpine:latest

# Install zsh, git, and bash for testing
RUN apk add --no-cache \
    zsh \
    git \
    bash \
    curl \
    jq

# Set zsh as default shell
RUN chsh -s /bin/zsh

# Create test user to avoid running as root
RUN adduser -D -s /bin/zsh testuser

# Switch to test user
USER testuser
WORKDIR /home/testuser

# Set up basic git config for testing
RUN git config --global user.name "Test User" && \
    git config --global user.email "test@example.com" && \
    git config --global init.defaultBranch main

# Install BATS testing framework
RUN git clone https://github.com/bats-core/bats-core.git /tmp/bats && \
    sudo /tmp/bats/install.sh /usr/local && \
    rm -rf /tmp/bats

# Create test workspace
RUN mkdir -p /home/testuser/test-workspace

# Set working directory for tests
WORKDIR /home/testuser/test-workspace

# Default command
CMD ["/bin/zsh"]